require 'davinci_dtr_test_kit/full_ehr/v2.2.0/cql_error/log_questionnaire_errors_no_phi_attestation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220LogQuestionnaireErrorsNoPHIAttestationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  before do
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
  end

  def create_log_errors_request(tags: [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG])
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$log-questionnaire-errors',
      test_session_id: test_session.id,
      result:,
      request_body: { resourceType: 'Parameters' }.to_json,
      tags:,
      status: 204
    )
  end

  it 'skips when no $log-questionnaire-errors request was made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('A $log-questionnaire-errors request must be made')
  end

  it 'waits for a true or false attestation that the logged OperationOutcome has no PHI' do
    create_log_errors_request

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include('do **not** contain information')
    expect(result.result_message).to match(%r{\[Click here\]\(\S+/resume_pass\?token=\h{64}\) if .* \*\*true\*\*})
    expect(result.result_message).to match(%r{\[Click here\]\(\S+/resume_fail\?token=\h{64}\) if .* \*\*false\*\*})
  end

  it 'verifies oper-2-B' do
    expect(described_class.verifies_requirements).to eq(['hl7.fhir.us.davinci-dtr_2.2.0@oper-2-B'])
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_log_errors_no_phi_attestation_spec_test
        config options: { dtr_workflow_tag: 'cql_error' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    end

    it 'ignores requests tagged for a different workflow' do
      create_log_errors_request(tags: [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG, 'other'])

      expect(run(scoped_test_class).result).to eq('skip')
    end

    it 'asks for the attestation when the workflow logged an error' do
      create_log_errors_request(tags: [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG, 'cql_error'])

      expect(run(scoped_test_class).result).to eq('wait')
    end
  end
end
