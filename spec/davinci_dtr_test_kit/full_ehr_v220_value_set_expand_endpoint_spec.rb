require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::MockPayer::FullEHRV220ValueSetExpandEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:client_id) { 'test_client_id' }
  let(:server_endpoint) { "/custom/#{suite_id}/fhir/ValueSet/$expand" }
  let(:value_sets_fixture) { 'cql_and_value_sets/cql_and_value_sets_value_sets.json' }
  let(:toppings_url) { 'https://inferno.healthit.gov/test-kits/davinci-dtr/ValueSet/toppings' }
  let(:expanded_marker_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUDE_VALUE_SET_EXPANDED_URL }

  let(:value_set_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_vs_expand_endpoint_spec_fixture_test
      config options: {
        value_set_bundle_fixture: 'cql_and_value_sets/cql_and_value_sets_value_sets.json',
        dtr_workflow_tag: 'custom_workflow'
      }
    end
  end

  let(:value_set_input_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_vs_expand_endpoint_spec_input_test
      input :value_set_bundle, optional: true
      config options: { value_set_bundle_input: 'value_set_bundle', dtr_workflow_tag: nil }
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
    DaVinciDTRTestKit::FixtureLoader.instance.instance_variable_set(:@cache, {})
  end

  def authorize
    header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
  end

  def get_expand(params)
    authorize
    get(server_endpoint, params)
  end

  def post_expand(body)
    authorize
    post(server_endpoint, body, 'CONTENT_TYPE' => 'application/json')
  end

  def parameters(*params)
    FHIR::Parameters.new(parameter: params.map { |param| FHIR::Parameters::Parameter.new(param) }).to_json
  end

  def response_resource
    FHIR.from_contents(last_response.body)
  end

  context 'when the requested ValueSet is in the configured Bundle' do
    before { run(value_set_fixture_test, client_id:) }

    it 'returns the expanded ValueSet for a GET with the url parameter' do
      get_expand(url: toppings_url)

      expect(last_response.status).to eq(200)
      expect(last_response.headers['Content-Type']).to include('application/fhir+json')
      expect(response_resource.url).to eq(toppings_url)
      expect(response_resource.expansion.contains).to be_present
    end

    it 'sets the expansion timestamp to the current time' do
      get_expand(url: toppings_url)

      expect(Time.parse(response_resource.expansion.timestamp)).to be_within(60).of(Time.now)
    end

    it 'removes Inferno control extensions' do
      get_expand(url: toppings_url)

      expect(last_response.body).to_not include(expanded_marker_url)
    end

    it 'does not change the configured Bundle' do
      get_expand(url: toppings_url)

      fixture = DaVinciDTRTestKit::FixtureLoader.instance[value_sets_fixture]
      toppings = fixture.entry.map(&:resource).find { |resource| resource.url == toppings_url }
      expect(Time.parse(toppings.expansion.timestamp)).to_not be_within(60).of(Time.now)
      expect(toppings.extension.map(&:url)).to include(expanded_marker_url)
    end

    it 'matches the valueSetVersion parameter' do
      get_expand(url: toppings_url, valueSetVersion: '1.0.0')
      expect(last_response.status).to eq(200)

      get_expand(url: toppings_url, valueSetVersion: '9.9.9')
      expect(last_response.status).to eq(404)
    end

    it 'returns the expanded ValueSet for a POST with a url parameter' do
      post_expand(parameters({ name: 'url', valueUri: toppings_url }))

      expect(last_response.status).to eq(200)
      expect(response_resource.url).to eq(toppings_url)
    end

    it 'returns the expanded ValueSet for a POST with a valueSet parameter' do
      post_expand(parameters({ name: 'valueSet',
                               resource: FHIR::ValueSet.new(url: toppings_url, status: 'active') }))

      expect(last_response.status).to eq(200)
      expect(response_resource.expansion.contains).to be_present
    end

    it 'returns 404 with OperationOutcome for a ValueSet that is not configured' do
      get_expand(url: 'https://example.org/ValueSet/unknown')

      expect(last_response.status).to eq(404)
      expect(response_resource).to be_a(FHIR::OperationOutcome)
      expect(response_resource.issue.first.code).to eq('not-found')
    end

    it 'returns 400 with OperationOutcome when no ValueSet is identified' do
      get_expand({})

      expect(last_response.status).to eq(400)
      expect(response_resource.issue.first.code).to eq('required')
    end

    it 'returns 400 with OperationOutcome when the POST body is not a Parameters resource' do
      post_expand(FHIR::ValueSet.new(url: toppings_url, status: 'active').to_json)

      expect(last_response.status).to eq(400)
      expect(response_resource.issue.first.code).to eq('invalid')
    end

    it 'tags the request with the ValueSet expand and workflow tags' do
      get_expand(url: toppings_url)

      tagged = requests_repo.tagged_requests(test_session.id,
                                             [DaVinciDTRTestKit::CLIENT_VALUE_SET_EXPAND_TAG, 'custom_workflow'])
      expect(tagged.length).to eq(1)
    end

    it 'sets the Access-Control-Allow-Origin header' do
      get_expand(url: toppings_url)

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'uses the session_path query parameter as the test run identifier when no Authorization header is present' do
      get(server_endpoint, url: toppings_url, session_path: client_id)

      expect(last_response.status).to eq(200)
    end

    it 'returns 401 when the token has expired' do
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)}")
      get(server_endpoint, url: toppings_url)

      expect(last_response.status).to eq(401)
    end
  end

  context 'when the ValueSets come from an input' do
    let(:unexpanded_bundle) do
      FHIR::Bundle.new(
        type: 'collection',
        entry: [FHIR::Bundle::Entry.new(resource: FHIR::ValueSet.new(url: 'https://example.org/ValueSet/no-expansion',
                                                                     status: 'active'))]
      ).to_json
    end

    it 'returns 400 with OperationOutcome when the ValueSet has no expansion' do
      run(value_set_input_test, client_id:, value_set_bundle: unexpanded_bundle)
      get_expand(url: 'https://example.org/ValueSet/no-expansion')

      expect(last_response.status).to eq(400)
      expect(response_resource.issue.first.code).to eq('not-supported')
    end

    it 'returns 404 with OperationOutcome when no ValueSet Bundle was provided' do
      run(value_set_input_test, client_id:)
      get_expand(url: toppings_url)

      expect(last_response.status).to eq(404)
    end
  end
end
