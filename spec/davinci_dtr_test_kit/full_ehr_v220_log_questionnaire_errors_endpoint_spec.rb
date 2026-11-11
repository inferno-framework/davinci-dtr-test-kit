require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::MockPayer::FullEHRV220LogQuestionnaireErrorsEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:test_runs_repo) { Inferno::Repositories::TestRuns.new }
  let(:client_id) { 'test_client_id' }
  let(:server_endpoint) { "/custom/#{suite_id}/fhir/Questionnaire/$log-questionnaire-errors" }
  let(:questionnaire_canonical) { 'http://hl7.org/fhir/us/davinci-dtr/Questionnaire/home-o2-std-questionnaire|2.2.0' }
  let(:log_errors_parameters) do
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'questionnaire', valueCanonical: questionnaire_canonical),
        FHIR::Parameters::Parameter.new(
          name: 'operationOutcome',
          resource: FHIR::OperationOutcome.new(
            issue: [
              FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'processing',
                                                diagnostics: 'Unable to evaluate a Questionnaire expression.')
            ]
          )
        )
      ]
    ).to_json
  end

  let(:wait_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_log_questionnaire_errors_endpoint_spec_test
      config options: { dtr_workflow_tag: 'custom_workflow' }
    end
  end

  # from inferno core (spec/runnable_context.rb) since described class is not a Runnable
  def run(runnable, inputs = {}, scratch = {})
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(runnable) unless tests_repo.exists?(runnable.id.to_s)

    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |original_name, value|
      name = runnable.config.input_name(original_name).presence || original_name
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.available_inputs[name.to_sym]&.type
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable, scratch)
  end

  before do
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
  end

  def authorize(token_lifetime_minutes = 5)
    header('Authorization',
           "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, token_lifetime_minutes)}")
  end

  def post_log_errors(body)
    post(server_endpoint, body, 'CONTENT_TYPE' => 'application/fhir+json')
  end

  context 'when a session is waiting for the request' do
    before { run(wait_test, client_id:) }

    it 'returns 204 with no content for a $log-questionnaire-errors request' do
      authorize
      post_log_errors(log_errors_parameters)

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end

    it 'returns 204 when the body is not a Parameters resource, leaving conformance to later tests' do
      authorize
      post_log_errors(FHIR::OperationOutcome.new.to_json)

      expect(last_response.status).to eq(204)
    end

    it 'returns 204 when the request has no body' do
      authorize
      post_log_errors('')

      expect(last_response.status).to eq(204)
    end

    it 'persists the request with the log questionnaire errors and workflow tags' do
      authorize
      post_log_errors(log_errors_parameters)

      tagged = requests_repo.tagged_requests(test_session.id,
                                             [DaVinciDTRTestKit::CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG,
                                              'custom_workflow'])
      expect(tagged.length).to eq(1)
      expect(tagged.first.status).to eq(204)
      expect(requests_repo.find_full_request(tagged.first.id).request_body).to eq(log_errors_parameters)
    end

    it 'leaves the session waiting for further requests' do
      authorize
      post_log_errors(log_errors_parameters)

      expect(test_runs_repo.find_latest_waiting_by_identifier(client_id)).to be_present
    end

    it 'sets the Access-Control-Allow-Origin header' do
      authorize
      post_log_errors(log_errors_parameters)

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'uses the session_path query parameter as the test run identifier when no Authorization header is present' do
      post("#{server_endpoint}?session_path=#{client_id}", log_errors_parameters,
           'CONTENT_TYPE' => 'application/fhir+json')

      expect(last_response.status).to eq(204)
    end

    it 'returns 401 when the token has expired' do
      authorize(-1)
      post_log_errors(log_errors_parameters)

      expect(last_response.status).to eq(401)
    end
  end

  context 'when no session is waiting for the request' do
    it 'returns 500 with a no waiting session error' do
      authorize
      post_log_errors(log_errors_parameters)

      expect(last_response.status).to eq(500)
      expect(last_response.body).to include('not associated with a waiting session')
    end
  end
end
