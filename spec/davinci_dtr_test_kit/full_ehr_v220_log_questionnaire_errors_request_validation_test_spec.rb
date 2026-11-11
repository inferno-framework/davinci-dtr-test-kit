require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_log_questionnaire_errors_request_validation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220LogQuestionnaireErrorsRequestValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:log_errors_url) { described_class.new.log_questionnaire_errors_url }
  let(:qp_url) { described_class.new.questionnaire_package_url }
  let(:questionnaire_url) { 'urn:inferno:dtr-test-kit:dinner-order-cql-error' }
  let(:questionnaire_canonical) { "#{questionnaire_url}|1.0.0" }

  before do
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
  end

  # Results returned directly by `run` never carry their `messages` (see the $questionnaire-package
  # request validation spec), so reload from the session to see per-message detail.
  def messages_for(run_result, type: nil)
    run_messages = Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages || []
    run_messages = run_messages.select { |message| message.type == type } if type
    run_messages.map(&:message)
  end

  def create_log_errors_request(request_body, url: log_errors_url,
                                tags: [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG])
    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      request_body:,
      tags:,
      status: 204
    )
  end

  def create_qp_request(*questionnaire_hashes, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
    response_body = {
      resourceType: 'Parameters',
      parameter: questionnaire_hashes.map do |questionnaire_hash|
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire_hash }] } }
      end
    }.to_json
    repo_create(
      :request,
      direction: 'incoming',
      url: qp_url,
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags:,
      status: 200
    )
  end

  def returned_questionnaire(url: questionnaire_url, version: '1.0.0')
    { resourceType: 'Questionnaire', status: 'active', url:, version:, item: [{ linkId: '1', type: 'string' }] }.compact
  end

  def params_json(*parameters)
    { resourceType: 'Parameters', parameter: parameters }.to_json
  end

  def questionnaire_param(canonical = questionnaire_canonical)
    { name: 'questionnaire', valueCanonical: canonical }
  end

  def outcome_param
    { name: 'operationOutcome',
      resource: { resourceType: 'OperationOutcome',
                  issue: [{ severity: 'error', code: 'processing',
                            diagnostics: 'Unable to compile the calculatedExpression CQL.' }] } }
  end

  def stub_valid_resource
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)
  end

  it 'skips when no $log-questionnaire-errors requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('A $log-questionnaire-errors request must be made')
  end

  it 'fails and reports the wrong URL when the request was not made to the $log-questionnaire-errors endpoint' do
    stub_valid_resource
    create_log_errors_request(params_json(questionnaire_param, outcome_param), url: '/some/other/url')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/Request made to wrong URL/))
  end

  it 'fails when the request body is not valid JSON' do
    create_log_errors_request('not json')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/does not contain a recognized FHIR resource/))
  end

  it 'fails when the request body is a FHIR resource other than Parameters' do
    create_log_errors_request({ resourceType: 'OperationOutcome', issue: [] }.to_json)

    expect_any_instance_of(described_class).to_not receive(:resource_is_valid?)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/Request is not FHIR Parameters resource/))
  end

  it 'validates the request Parameters against the log errors input parameters profile' do
    create_log_errors_request(params_json(questionnaire_param, outcome_param))
    validated_with = nil
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |_instance, **kwargs|
      validated_with = kwargs
      true
    end

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(validated_with).to include(
      resource: an_instance_of(FHIR::Parameters),
      profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-log-errors-input-parameters|2.2.0'
    )
  end

  it 'fails when the validator rejects the resource' do
    allow_any_instance_of(described_class).to receive(:resource_is_valid?) do |test_instance|
      test_instance.add_message('error', 'Resource is not conformant to the profile.')
      false
    end
    create_log_errors_request(params_json(questionnaire_param, outcome_param))

    result = run(described_class)

    expect(result.result).to eq('fail')
  end

  describe 'the logged Questionnaire canonical' do
    before { stub_valid_resource }

    it 'passes when the canonical matches the Questionnaire Inferno returned' do
      create_qp_request(returned_questionnaire)
      create_log_errors_request(params_json(questionnaire_param, outcome_param))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
      expect(messages_for(result, type: 'warning')).to be_empty
    end

    it 'warns, but passes, when the canonical is not version-specific' do
      create_qp_request(returned_questionnaire)
      create_log_errors_request(params_json(questionnaire_param(questionnaire_url), outcome_param))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
      expect(messages_for(result, type: 'warning')).to include(a_string_matching(/not version-specific/))
    end

    it 'fails when the canonical identifies a Questionnaire Inferno did not return' do
      create_qp_request(returned_questionnaire)
      create_log_errors_request(params_json(questionnaire_param('http://example.org/Questionnaire/other|1.0.0'),
                                            outcome_param))

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(messages_for(result))
        .to include(a_string_matching(/does not identify a Questionnaire returned by Inferno/))
    end

    it 'fails when the canonical version does not match the returned Questionnaire version' do
      create_qp_request(returned_questionnaire)
      create_log_errors_request(params_json(questionnaire_param("#{questionnaire_url}|9.9.9"), outcome_param))

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(messages_for(result))
        .to include(a_string_matching(/does not identify a Questionnaire returned by Inferno/))
    end

    it 'passes without the cross-check when Inferno did not return any Questionnaire' do
      create_log_errors_request(params_json(questionnaire_param, outcome_param))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end
  end

  it 'aggregates errors across multiple requests and reports which request numbers had them' do
    stub_valid_resource
    create_qp_request(returned_questionnaire)
    create_log_errors_request(params_json(questionnaire_param, outcome_param))
    create_log_errors_request(params_json(questionnaire_param('http://example.org/Questionnaire/other|1.0.0'),
                                          outcome_param))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/\ARequest 2: /)
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_log_errors_request_validation_spec_test
        config options: { dtr_workflow_tag: 'cql_error' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
      stub_valid_resource
    end

    it 'ignores requests tagged for a different workflow' do
      create_log_errors_request(
        params_json(questionnaire_param, outcome_param),
        tags: [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG, 'some_other_workflow']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('skip')
    end

    it 'only considers requests and returned Questionnaires tagged for the configured workflow' do
      create_qp_request(returned_questionnaire(url: 'http://example.org/Questionnaire/other-workflow'),
                        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'some_other_workflow'])
      create_qp_request(returned_questionnaire,
                        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'cql_error'])
      create_log_errors_request(
        params_json(questionnaire_param, outcome_param),
        tags: [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG, 'cql_error']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('pass'), result.result_message
    end
  end
end
