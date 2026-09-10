require 'davinci_dtr_test_kit/server/v2.2.0/dtr_payer_server_suite'

RSpec.describe DaVinciDTRTestKit::MockPayer::PayerProxyEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:suite) { Inferno::Repositories::TestSuites.new.find(suite_id) }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:runnable) do
    Class.new(DaVinciDTRTestKit::DTRPayerServerV220::InteractionTest) do
      id :dtr_v220_payer_proxy_endpoint_spec_interaction
      input :backend_services_smart_auth_info, type: :auth_info, optional: true
      input :smart_auth_info, type: :auth_info, optional: true
    end
  end
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:url) { 'https://payer.example.com/fhir' }
  let(:dtr_client_access_token) { 'client-flow-token' }
  let(:backend_access_token) { 'backend-services-token' }
  let(:request_body) do
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'url', valueUri: 'http://example.com/vs')]
    ).to_json
  end

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

  def start_proxy_wait(auth_info_name: :backend_services_smart_auth_info)
    inputs = {
      url:,
      request_mode: DaVinciDTRTestKit::DTRPayerServerV220::InteractionTest::CLIENT_MODE,
      dtr_client_access_token: dtr_client_access_token,
      auth_info_name => { access_token: backend_access_token }
    }
    result = run(runnable, inputs)
    expect(result.result).to eq('wait'), result.result_message
    result
  end

  it 'does not proxy a request without the DTR client-flow bearer token' do
    start_proxy_wait
    post("/custom/#{suite_id}#{DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_PATH}", request_body)

    expect(last_response.status).to eq(500)
    expect(WebMock).to_not have_requested(:post, /payer\.example\.com/)
  end

  shared_examples 'a proxied operation' do |path:, payer_path:, tag:|
    it 'forwards one client request, returns the payer response, and stores one tagged request' do
      start_proxy_wait
      payer_response_body = FHIR::OperationOutcome.new.to_json
      stub_request(:post, "#{url}#{payer_path}")
        .with(
          body: request_body,
          headers: {
            'Authorization' => "Bearer #{backend_access_token}",
            'Content-Type' => 'application/fhir+json'
          }
        )
        .to_return(status: 202, body: payer_response_body, headers: { 'Content-Type' => 'application/foo+json' })

      header 'Authorization', "Bearer #{dtr_client_access_token}"
      post("/custom/#{suite_id}#{path}", request_body, 'CONTENT_TYPE' => 'application/custom+json; charset=utf-8')

      expect(last_response.status).to eq(202), last_response.body
      expect(last_response.body).to eq(payer_response_body)
      expect(last_response.headers['Content-Type']).to eq('application/foo+json')
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
      expect(WebMock).to have_requested(:post, "#{url}#{payer_path}").once

      requests = requests_repo.tagged_requests(test_session.id, [tag])
      expect(requests.length).to eq(1)
      stored_request = requests_repo.find_full_request(requests.first.id)
      expect(stored_request.direction).to eq('outgoing')
      expect(stored_request.url).to eq("#{url}#{payer_path}")
      expect(stored_request.request_body).to eq(request_body)
      expect(stored_request.response_body).to eq(payer_response_body)
      expect(stored_request.tags).to include(tag)
    end
  end

  it 'forwards malformed JSON without changing its body' do
    start_proxy_wait
    request_body = '{not valid JSON'
    payer_response_body = FHIR::OperationOutcome.new.to_json
    stub_request(:post, "#{url}/Questionnaire/$questionnaire-package")
      .with(body: request_body, headers: { 'Content-Type' => 'application/fhir+json' })
      .to_return(status: 400, body: payer_response_body, headers: { 'Content-Type' => 'application/fhir+json' })

    header 'Authorization', "Bearer #{dtr_client_access_token}"
    post("/custom/#{suite_id}#{DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_PATH}", request_body,
         'CONTENT_TYPE' => 'application/custom+json')

    expect(last_response.status).to eq(400), last_response.body
    expect(last_response.body).to eq(payer_response_body)
  end

  it 'uses the legacy smart_auth_info input when backend services credentials are absent' do
    start_proxy_wait(auth_info_name: :smart_auth_info)
    stub_request(:post, "#{url}/Questionnaire/$questionnaire-package")
      .with(headers: { 'Authorization' => "Bearer #{backend_access_token}" })
      .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

    header 'Authorization', "Bearer #{dtr_client_access_token}"
    post("/custom/#{suite_id}#{DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_PATH}", request_body)

    expect(last_response.status).to eq(200)
  end

  it_behaves_like 'a proxied operation',
                  path: DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_PATH,
                  payer_path: '/Questionnaire/$questionnaire-package',
                  tag: DaVinciDTRTestKit::QUESTIONNAIRE_TAG
  it_behaves_like 'a proxied operation',
                  path: DaVinciDTRTestKit::NEXT_PATH,
                  payer_path: '/Questionnaire/$next-question',
                  tag: DaVinciDTRTestKit::NEXT_TAG
  it_behaves_like 'a proxied operation',
                  path: DaVinciDTRTestKit::VALUE_SET_EXPAND_PATH,
                  payer_path: '/ValueSet/$expand',
                  tag: DaVinciDTRTestKit::VALUE_SET_EXPAND_TAG
end
