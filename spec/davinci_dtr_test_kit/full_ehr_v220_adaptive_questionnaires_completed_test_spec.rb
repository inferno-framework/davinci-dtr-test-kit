require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/adaptive_questionnaires_completed_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220AdaptiveQuestionnairesCompletedTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  # Results returned directly by `run` never carry their `messages` (a repository quirk:
  # Results::create strips :messages from the params before building the in-memory entity,
  # even though it persists them), so reload from the session to see per-message detail.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  def create_request(response_body, tags:,
                     url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package')
    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags:,
      status: 200
    )
  end

  def create_qp_request(response_body, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
    create_request(response_body, tags:, url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package')
  end

  def create_nq_request(response_body, tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG])
    create_request(response_body, tags:, url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question')
  end

  def adaptive_questionnaire_hash(url:, version: nil, link_id: 'Adaptive')
    {
      resourceType: 'Questionnaire',
      status: 'active',
      url:,
      version:,
      extension: [
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueBoolean: true }
      ],
      item: [{ linkId: link_id, type: 'string' }]
    }.compact
  end

  def standard_questionnaire_hash(url:, link_id: 'Standard')
    {
      resourceType: 'Questionnaire',
      status: 'active',
      url:,
      item: [{ linkId: link_id, type: 'string' }]
    }
  end

  # $questionnaire-package's output Parameters carry one `packagebundle` entry per Questionnaire
  # returned; pass one questionnaire hash per bundle to mirror that.
  def qp_response_json(*questionnaire_hashes)
    {
      resourceType: 'Parameters',
      parameter: questionnaire_hashes.map do |questionnaire_hash|
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire_hash }] } }
      end
    }.to_json
  end

  # $next-question has a single "return" out parameter typed as a Resource, so per the FHIR spec
  # the conformant response is the raw QuestionnaireResponse rather than a Parameters wrapper --
  # this is also what Inferno's own simulated endpoint sends (full_ehr_next_question_endpoint.rb).
  def nq_response_json(questionnaire_hash, status: 'completed')
    { resourceType: 'QuestionnaireResponse', status:, contained: [questionnaire_hash] }.to_json
  end

  # Some payer implementations wrap the QuestionnaireResponse in a Parameters resource anyway;
  # Inferno tolerates that shape too.
  def nq_wrapped_response_json(questionnaire_hash, status: 'completed')
    {
      resourceType: 'Parameters',
      parameter: [
        { name: 'return',
          resource: { resourceType: 'QuestionnaireResponse', status:, contained: [questionnaire_hash] } }
      ]
    }.to_json
  end

  it 'skips when no Questionnaire Package request returned a Questionnaire' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'skips by default when only standard (non-adaptive) Questionnaires were returned' do
    create_qp_request(qp_response_json(standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std')))

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq(
      'Adaptive Questionnaires required to be demonstrated during this scenario but none were returned.'
    )
  end

  it 'passes when a returned adaptive Questionnaire is completed via a matching $next-question response' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
    create_qp_request(qp_response_json(adaptive))
    create_nq_request(nq_response_json(adaptive))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'also accepts a $next-question response with the QuestionnaireResponse wrapped in Parameters' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
    create_qp_request(qp_response_json(adaptive))
    create_nq_request(nq_wrapped_response_json(adaptive))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'matches canonicals that include a version' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1', version: '1.0.0')
    create_qp_request(qp_response_json(adaptive))
    create_nq_request(nq_response_json(adaptive))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when the completed Questionnaire has a different version than the one returned' do
    returned = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1', version: '1.0.0')
    completed = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1', version: '2.0.0')
    create_qp_request(qp_response_json(returned))
    create_nq_request(nq_response_json(completed))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      'Adaptive Questionnaire with canonical url `http://example.org/Questionnaire/adaptive1|1.0.0` ' \
      'was never completed.'
    )
  end

  it 'fails and reports the canonical url when an adaptive Questionnaire is never completed' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
    create_qp_request(qp_response_json(adaptive))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'Adaptive Questionnaires retrieved but not completed. See Messages for details.'
    )
    expect(messages_for(result)).to include(
      'Adaptive Questionnaire with canonical url `http://example.org/Questionnaire/adaptive1` was never completed.'
    )
  end

  it 'does not count a $next-question response whose QuestionnaireResponse status is not completed' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
    create_qp_request(qp_response_json(adaptive))
    create_nq_request(nq_response_json(adaptive, status: 'in-progress'))

    result = run(described_class)

    expect(result.result).to eq('fail')
  end

  it 'only reports adaptive Questionnaires still outstanding, not ones already completed' do
    completed = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/completed', link_id: 'A')
    outstanding = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/outstanding', link_id: 'B')
    create_qp_request(qp_response_json(completed, outstanding))
    create_nq_request(nq_response_json(completed))

    result = run(described_class)

    expect(result.result).to eq('fail')
    messages = messages_for(result)
    expect(messages).to include(
      'Adaptive Questionnaire with canonical url `http://example.org/Questionnaire/outstanding` was never completed.'
    )
    expect(messages).to_not include(
      'Adaptive Questionnaire with canonical url `http://example.org/Questionnaire/completed` was never completed.'
    )
  end

  it 'treats $questionnaire-package responses that are not valid JSON as returning no Questionnaire' do
    create_qp_request('not json')

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'treats $questionnaire-package responses that are not a Parameters resource as returning no Questionnaire' do
    create_qp_request({ resourceType: 'OperationOutcome', issue: [] }.to_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'ignores $next-question responses that are not valid JSON, still failing on the outstanding Questionnaire' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
    create_qp_request(qp_response_json(adaptive))
    create_nq_request('not json')

    result = run(described_class)

    expect(result.result).to eq('fail')
  end

  it 'ignores $next-question responses that are not a QuestionnaireResponse resource' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
    create_qp_request(qp_response_json(adaptive))
    create_nq_request({ resourceType: 'OperationOutcome', issue: [] }.to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
  end

  it 'aggregates across multiple $questionnaire-package and $next-question requests' do
    first = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/first', link_id: 'A')
    second = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/second', link_id: 'B')
    create_qp_request(qp_response_json(first))
    create_qp_request(qp_response_json(second))
    create_nq_request(nq_response_json(first))
    create_nq_request(nq_response_json(second))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_adaptive_questionnaires_completed_spec_test
        config options: { dtr_workflow_tag: 'additional_must_support' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    end

    it 'ignores requests tagged for a different workflow' do
      adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
      create_qp_request(
        qp_response_json(adaptive),
        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'some_other_workflow']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
    end

    it 'only considers requests tagged for the configured workflow' do
      adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
      create_qp_request(
        qp_response_json(adaptive),
        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'additional_must_support']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('fail')
    end
  end

  describe 'config.options[:adaptive_questionnaires_optional]' do
    let(:optional_test_class) do
      Class.new(described_class) do
        id :adaptive_questionnaires_optional_spec_test
        config options: { adaptive_questionnaires_optional: true }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(optional_test_class) unless tests_repo.exists?(optional_test_class.id.to_s)
    end

    it 'passes vacuously when only standard Questionnaires were returned' do
      create_qp_request(qp_response_json(standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std')))

      result = run(optional_test_class)

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq(
        'No adaptive Questionnaires returned for completion during this interaction.'
      )
    end

    it 'sets scratch[:short_circuit_adaptive] so downstream $next-question tests can short-circuit too' do
      create_qp_request(qp_response_json(standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std')))
      scratch = {}

      run(optional_test_class, {}, scratch)

      expect(scratch[:short_circuit_adaptive]).to eq(:pass)
    end

    it 'still skips when no Questionnaire Package request returned a Questionnaire at all' do
      result = run(optional_test_class)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
    end

    it 'still validates completion normally, without setting the short-circuit flag, when adaptive ' \
       'Questionnaires are actually returned' do
      adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
      create_qp_request(qp_response_json(adaptive))
      scratch = {}

      result = run(optional_test_class, {}, scratch)

      expect(result.result).to eq('fail')
      expect(scratch).to_not have_key(:short_circuit_adaptive)
    end
  end

  describe 'clearing a stale scratch[:short_circuit_adaptive] flag' do
    it 'does not let a flag left over from a previous run affect a run with adaptive Questionnaires present' do
      adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1')
      create_qp_request(qp_response_json(adaptive))
      create_nq_request(nq_response_json(adaptive))
      scratch = { short_circuit_adaptive: :pass }

      result = run(described_class, {}, scratch)

      expect(result.result).to eq('pass'), result.result_message
      expect(scratch).to_not have_key(:short_circuit_adaptive)
    end
  end

  describe 'short-circuiting via scratch[:short_circuit]' do
    it 'passes immediately with the default message when flagged to pass' do
      result = run(described_class, {}, { short_circuit: :pass })

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('No Questionnaires need to be completed.')
    end

    it 'skips immediately with the default message when flagged to skip' do
      result = run(described_class, {}, { short_circuit: :skip })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Failed to setup the Inferno DTR payer server simulation.')
    end

    it 'fails immediately with the default message when flagged to fail' do
      result = run(described_class, {}, { short_circuit: :fail })

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Failed to setup the Inferno DTR payer server simulation.')
    end

    it 'uses the configured short_circuit_pass_message when passing' do
      test_class = Class.new(described_class) do
        id :short_circuit_message_adaptive_questionnaires_completed_spec_test
        config options: { short_circuit_pass_message: 'Tester declined to complete Questionnaires.' }
      end
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)

      result = run(test_class, {}, { short_circuit: :pass })

      expect(result.result).to eq('pass')
      expect(result.result_message).to eq('Tester declined to complete Questionnaires.')
    end
  end
end
