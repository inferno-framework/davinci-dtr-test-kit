require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_questionnaire_package_request_validation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnairePackageRequestValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:qp_url) { described_class.new.questionnaire_package_url }

  # Results returned directly by `run` never carry their `messages` (a repository quirk:
  # Results::create strips :messages from the params before building the in-memory entity,
  # even though it persists them), so reload from the session to see per-message detail.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  def create_qp_request(request_body, url: qp_url, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      request_body:,
      tags:,
      status: 200
    )
  end

  def params_json(*parameters)
    { resourceType: 'Parameters', parameter: parameters }.to_json
  end

  def coverage_param
    { name: 'coverage', resource: { resourceType: 'Coverage', status: 'active' } }
  end

  def order_param
    { name: 'order', resource: { resourceType: 'ServiceRequest', status: 'draft', intent: 'order' } }
  end

  def context_param
    { name: 'context', valueString: 'some-crd-context-id' }
  end

  def questionnaire_param
    { name: 'questionnaire', valueCanonical: 'http://example.org/Questionnaire/std1' }
  end

  def stub_valid_resource
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)
  end

  it 'skips when no Questionnaire Package requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('A Questionnaire Package request must be made')
  end

  it 'fails and reports the wrong URL when the request was not made to the $questionnaire-package endpoint' do
    stub_valid_resource
    create_qp_request(params_json(order_param, coverage_param), url: '/some/other/url')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/Request made to wrong URL/))
  end

  it 'fails when the request body is not valid JSON' do
    create_qp_request('not json')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/does not contain a recognized FHIR resource/))
  end

  it 'fails when the request body is a FHIR resource other than Parameters' do
    create_qp_request({ resourceType: 'OperationOutcome', issue: [] }.to_json)

    expect_any_instance_of(described_class).to_not receive(:resource_is_valid?)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/Request is not FHIR Parameters resource/))
  end

  it 'validates the request Parameters against the questionnaire-package input parameters profile' do
    create_qp_request(params_json(order_param, coverage_param))
    validated_with = nil
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |_instance, **kwargs|
      validated_with = kwargs
      true
    end

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(validated_with).to include(
      resource: an_instance_of(FHIR::Parameters),
      profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.2.0'
    )
  end

  it 'fails when the validator rejects the resource' do
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |test_instance|
      test_instance.add_message('error', 'Resource is not conformant to the profile.')
      false
    end
    create_qp_request(params_json(order_param, coverage_param))

    result = run(described_class)

    expect(result.result).to eq('fail')
  end

  describe 'required invocation details (a Questionnaire canonical, an order/context resource, or CRD context)' do
    it 'passes when the request includes an order parameter alongside coverage' do
      stub_valid_resource
      create_qp_request(params_json(coverage_param, order_param))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'passes when the request includes a context parameter' do
      stub_valid_resource
      create_qp_request(params_json(coverage_param, context_param))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'passes when the request includes a questionnaire canonical parameter' do
      stub_valid_resource
      create_qp_request(params_json(coverage_param, questionnaire_param))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'fails and reports the missing invocation details when the request has none of them' do
      stub_valid_resource
      create_qp_request(params_json(coverage_param))

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(messages_for(result)).to include(
        a_string_matching(/does not contain a Questionnaire canonical, a request resource, or context/)
      )
    end
  end

  it 'aggregates errors across multiple requests and reports which request numbers had them' do
    stub_valid_resource
    create_qp_request(params_json(coverage_param, order_param))
    create_qp_request(params_json(coverage_param))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/\ARequest 2: /)
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_qp_request_validation_spec_test
        config options: { dtr_workflow_tag: 'additional_must_support' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    end

    it 'ignores requests tagged for a different workflow' do
      create_qp_request(
        params_json(coverage_param, order_param),
        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'some_other_workflow']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('skip')
    end

    it 'only considers requests tagged for the configured workflow' do
      stub_valid_resource
      create_qp_request(
        params_json(coverage_param, order_param),
        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'additional_must_support']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('pass'), result.result_message
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
  end
end
