require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::MockPayer::FullEHRV220QuestionnairePackageEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:suite) { Inferno::Repositories::TestSuites.new.find(suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:client_id) { 'test_client_id' }
  let(:inclusion_criteria_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUSION_CRITERIA_URL }
  let(:request_range_url) { DaVinciDTRTestKit::InfernoControlExtensions::REQUEST_RANGE_URL }
  let(:include_resource_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUDE_RESOURCE_URL }
  let(:server_endpoint) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }

  let(:valid_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
  end

  let(:valid_parameters_template_json) do
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'PackageBundle',
          resource: FHIR::Bundle.new(type: 'collection')
        )
      ]
    ).to_json
  end

  # Each subclass of DTRFullEHRV220InteractionWaitTest sets the config options the endpoint
  # reads from test.config.options to resolve the response template. This lets each test
  # exercise a distinct configuration path without suite navigation or response stubs.

  # No config → endpoint returns "no template source" error
  let(:no_template_test) { DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest }

  # Fixture path (valid Parameters): exercises the happy path for fixture-based templates
  let(:parameters_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_parameters_fixture_test
      config options: {
        qp_response_template_fixture: 'questionnaire_package_request_parameters_example.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # Fixture path (Bundle, not Parameters): exercises the wrong-resource-type error path
  let(:bundle_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_bundle_fixture_test
      config options: {
        qp_response_template_fixture: 'dinner_static/questionnaire_dinner_order_static.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # Fixture path (missing file): exercises the file-not-found error path
  let(:missing_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_missing_fixture_test
      config options: {
        qp_response_template_fixture: 'nonexistent/fixture.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # Fixture path (valid JSON, not FHIR): exercises the non-FHIR-resource error path
  let(:non_fhir_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_non_fhir_fixture_test
      config options: {
        qp_response_template_fixture: 'non_fhir.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # Fixture path (Parameters with FHIRPath): exercises the fhirpath-in-fixture error path
  let(:fhirpath_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_fhirpath_fixture_test
      config options: {
        qp_response_template_fixture: 'fhirpath_fixture.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # Input path: user supplies a Parameters JSON via the qp_response_template input
  let(:input_template_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_input_test
      input :qp_response_template, optional: true
      config options: { qp_response_template_input: 'qp_response_template', dtr_workflow_tag: nil }
    end
  end

  # Input path with qp_single_use enabled: only the first request gets a successful response
  let(:single_use_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_single_use_test
      input :qp_response_template, optional: true
      config options: {
        qp_response_template_input: 'qp_response_template',
        qp_single_use: true,
        dtr_workflow_tag: nil
      }
    end
  end

  # Input path with an additional dtr_workflow tag applied to the request
  let(:workflow_tagged_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_qp_endpoint_spec_workflow_test
      input :qp_response_template, optional: true
      config options: { qp_response_template_input: 'qp_response_template', dtr_workflow_tag: 'custom_workflow' }
    end
  end

  # from inferno core (spec/runnable_context.rb) since described class is not a Runnable
  def run(runnable, inputs = {}, scratch = {})
    # Subclasses created with Class.new are not auto-registered in Inferno's in-memory test
    # repository, which is validated when creating a test run. Register on first use.
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
    # Stub suite_id on all URLs instances so the wait-message interpolations in the test
    # run block succeed without requiring each subclass to be registered in a suite group.
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
    # FixtureLoader is a singleton with a persistent cache. Reset it before each example so
    # File.read stubs in individual tests are not defeated by a previously cached fixture.
    DaVinciDTRTestKit::FixtureLoader.instance.instance_variable_set(:@cache, {})
  end

  describe 'When responding' do
    def post_with_token
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')
    end

    def param_names
      JSON.parse(last_response.body).fetch('parameter', []).map { |p| p['name'] }
    end
    it 'returns 500 with OperationOutcome when no response template source is configured' do
      run(no_template_test, client_id:)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(500)
      expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
    end

    it 'returns 401 when the token has expired' do
      run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

      expired_token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)
      header('Authorization', "Bearer #{expired_token}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(401)
    end

    it 'sets the Access-Control-Allow-Origin header on 401 (expired token) responses' do
      run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

      expired_token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)
      header('Authorization', "Bearer #{expired_token}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(401)
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'uses the session_path query parameter as the test run identifier when no Authorization header is present' do
      run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

      post("#{server_endpoint}?session_path=#{client_id}", valid_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(200)
      tagged = requests_repo.tagged_requests(test_session.id, [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
      expect(tagged.length).to eq(1)
    end

    it 'returns 400 with OperationOutcome when the request body is not parseable as FHIR' do
      # Use text/plain to bypass the JSON middleware so the endpoint sees the raw body
      run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(server_endpoint, 'not valid fhir json', 'CONTENT_TYPE' => 'text/plain')

      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
    end

    it 'sets the Access-Control-Allow-Origin header to * on every response' do
      run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'tags the request with QUESTIONNAIRE_PACKAGE_TAG' do
      run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

      tagged = requests_repo.tagged_requests(test_session.id, [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
      expect(tagged.length).to eq(1)
    end

    it 'also applies the dtr_workflow_tag option as an additional request tag' do
      run(workflow_tagged_test, client_id:, qp_response_template: valid_parameters_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

      tagged = requests_repo.tagged_requests(
        test_session.id,
        [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'custom_workflow']
      )
      expect(tagged.length).to eq(1)
    end

    context 'when template parameters have FHIRPath inclusion criteria' do
      let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate" }

      # One unconditional parameter and one gated by a FHIRPath expression
      let(:template_with_criteria) do
        FHIR.from_contents({
          resourceType: 'Parameters',
          parameter: [
            { name: 'AlwaysIncluded', resource: { resourceType: 'Bundle', type: 'collection' } },
            { name: 'Conditional',
              extension: [{ url: inclusion_criteria_url,
                            valueExpression: { expression: 'true', language: 'text/fhirpath' } }],
              resource: { resourceType: 'Bundle', type: 'collection' } }
          ]
        }.to_json)
      end

      before do
        run(input_template_test, client_id:, qp_response_template: template_with_criteria.to_json)
      end

      it 'excludes a parameter when its FHIRPath expression evaluates to boolean false' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: false }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('Conditional')
      end

      it 'includes a parameter when its FHIRPath expression evaluates to boolean true' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded', 'Conditional')
      end

      it 'strips the inclusion-criteria extension from an included parameter' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        conditional_param = JSON.parse(last_response.body).fetch('parameter', [])
          .find { |p| p['name'] == 'Conditional' }
        extension_urls = conditional_param&.fetch('extension', [])&.map { |e| e['url'] } || []
        expect(extension_urls).to_not include(inclusion_criteria_url)
      end

      it 'includes a parameter when FHIRPath returns a single non-boolean result' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'string', element: 'some-value' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded', 'Conditional')
      end

      it 'excludes a parameter when FHIRPath returns an empty result set' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('Conditional')
      end

      it 'excludes a parameter when FHIRPath returns multiple results' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200,
          body: [{ type: 'boolean', element: true }, { type: 'boolean', element: false }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('Conditional')
      end

      it 'excludes a parameter when the FHIRPath service response is not parseable JSON' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: 'not valid json',
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('Conditional')
      end

      it 'returns 400 with OperationOutcome when the FHIRPath service returns a non-2xx status (input template)' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 422, body: 'FHIRPath evaluation error'
        )
        post_with_token

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 500 with OperationOutcome when the FHIRPath service returns a non-2xx status (fixture template)' do
        fixture_json = template_with_criteria.to_json
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(end_with('fhirpath_fixture.json')).and_return(fixture_json)
        run(fhirpath_fixture_test, client_id:)

        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 422, body: 'FHIRPath evaluation error'
        )
        post_with_token

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end
    end

    context 'when template parameters have request-range criteria' do
      # Range values are 1-indexed: "1" means the first request, "1-2" means the first two, etc.

      def build_range_template(range_string)
        FHIR.from_contents({
          resourceType: 'Parameters',
          parameter: [
            { name: 'AlwaysIncluded', resource: { resourceType: 'Bundle', type: 'collection' } },
            { name: 'RangeLimited',
              extension: [{ url: request_range_url, valueString: range_string }],
              resource: { resourceType: 'Bundle', type: 'collection' } }
          ]
        }.to_json).to_json
      end

      # Rack::Test does not set REQUEST_PATH, which the persistence callback uses when
      # constructing the stored URL. Without it the URL has no path and the
      # count_previous_requests URL filter never matches. Set it explicitly here so the
      # stored URL includes the path and the filter works correctly.
      def post_with_token
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => server_endpoint)
      end

      before do
        run(input_template_test, client_id:, qp_response_template: build_range_template('1-2'))
      end

      it 'includes the parameter on the first request (request 1, within 1-2)' do
        post_with_token

        expect(last_response.status).to eq(200)
        expect(param_names).to include('RangeLimited', 'AlwaysIncluded')
      end

      it 'strips the request-range extension from an included parameter' do
        post_with_token

        range_param = JSON.parse(last_response.body).fetch('parameter', [])
          .find { |p| p['name'] == 'RangeLimited' }
        extension_urls = range_param&.fetch('extension', [])&.map { |e| e['url'] } || []
        expect(extension_urls).to_not include(request_range_url)
      end

      it 'still includes the parameter on the second request (request 2, top of 1-2)' do
        post_with_token # request 1
        post_with_token # request 2

        expect(last_response.status).to eq(200)
        expect(param_names).to include('RangeLimited')
      end

      it 'excludes the parameter on the third request (request 3, outside 1-2)' do
        post_with_token # request 1
        post_with_token # request 2
        post_with_token # request 3

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('RangeLimited')
      end

      it 'supports comma-separated non-contiguous ranges' do
        run(input_template_test, client_id:, qp_response_template: build_range_template('1,3'))

        post_with_token # request 1 (in "1,3") → included
        expect(param_names).to include('RangeLimited')

        post_with_token # request 2 (not in "1,3") → excluded
        expect(param_names).to_not include('RangeLimited')

        post_with_token # request 3 (in "1,3") → included
        expect(param_names).to include('RangeLimited')
      end

      it 'does not advance the request slot counter for non-200 responses' do
        # A failed request (expired token → 401) must not consume a slot; the next valid
        # request should still be treated as slot 2 (inside range 1-2), not slot 3.
        post_with_token # slot 1 — 200, inside range 1-2
        expect(param_names).to include('RangeLimited')

        expired_token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)
        header('Authorization', "Bearer #{expired_token}")
        post(server_endpoint, valid_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => server_endpoint)
        expect(last_response.status).to eq(401)

        post_with_token # slot 2 (not 3) — still inside range 1-2
        expect(last_response.status).to eq(200)
        expect(param_names).to include('RangeLimited')
      end

      it 'returns 500 with OperationOutcome when the range string is invalid' do
        run(input_template_test, client_id:, qp_response_template: build_range_template('not-a-range'))
        post_with_token

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 500 with OperationOutcome when the range has inverted bounds (e.g. 3-1)' do
        run(input_template_test, client_id:, qp_response_template: build_range_template('3-1'))
        post_with_token

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end
    end

    context 'when a parameter has both FHIRPath and request-range criteria' do
      let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate" }

      # Template with one parameter carrying both criteria types
      let(:dual_criteria_template) do
        FHIR.from_contents({
          resourceType: 'Parameters',
          parameter: [
            { name: 'AlwaysIncluded', resource: { resourceType: 'Bundle', type: 'collection' } },
            { name: 'DualGated',
              extension: [
                { url: inclusion_criteria_url,
                  valueExpression: { expression: 'true', language: 'text/fhirpath' } },
                { url: request_range_url, valueString: '1-2' }
              ],
              resource: { resourceType: 'Bundle', type: 'collection' } }
          ]
        }.to_json).to_json
      end

      # Rack::Test does not set REQUEST_PATH; set it so count_previous_requests filters correctly.
      def post_with_token
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => server_endpoint)
      end

      before do
        run(input_template_test, client_id:, qp_response_template: dual_criteria_template)
      end

      it 'includes the parameter when both the FHIRPath expression and range are satisfied' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token # request 1, within range 1-2, FHIRPath true → included

        expect(last_response.status).to eq(200)
        expect(param_names).to include('DualGated')
      end

      it 'excludes the parameter when the range is satisfied but FHIRPath evaluates to false' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: false }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token # request 1, within range 1-2, FHIRPath false → excluded

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('DualGated')
      end

      it 'excludes the parameter when FHIRPath is satisfied but the range is not' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token # request 1 (within range)
        post_with_token # request 2 (within range)
        post_with_token # request 3, outside range 1-2, FHIRPath true → excluded

        expect(last_response.status).to eq(200)
        expect(param_names).to include('AlwaysIncluded')
        expect(param_names).to_not include('DualGated')
      end
    end

    context 'when the template contains {{fhirpath}} tokens' do
      let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate" }

      let(:template_with_token) do
        {
          resourceType: 'Parameters',
          parameter: [{ name: 'TestParam', valueString: '{{test.expression}}' }]
        }.to_json
      end

      before do
        run(input_template_test, client_id:, qp_response_template: template_with_token)
      end

      it 'replaces the token with the scalar FHIRPath result' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'string', element: 'replaced-value' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['parameter'].first['valueString']).to eq('replaced-value')
      end

      it 'substitutes an empty string when the FHIRPath expression returns no results' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
      end

      it 'returns 400 with OperationOutcome when the FHIRPath service returns a non-2xx status (input template)' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 422, body: 'FHIRPath evaluation error'
        )
        post_with_token

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 500 with OperationOutcome when the FHIRPath service returns a non-2xx status (fixture template)' do
        fixture_json = { resourceType: 'Parameters',
                         parameter: [{ name: 'TestParam', valueString: '{{test.expression}}' }] }.to_json
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(end_with('fhirpath_fixture.json')).and_return(fixture_json)
        run(fhirpath_fixture_test, client_id:)

        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 422, body: 'FHIRPath evaluation error'
        )
        post_with_token

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 400 with OperationOutcome when the replacement value makes the template JSON invalid' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'string', element: 'value"with"quotes' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'calls the FHIRPath service only once for duplicate tokens' do
        template_with_duplicates = {
          resourceType: 'Parameters',
          parameter: [
            { name: 'First', valueString: '{{test.expression}}' },
            { name: 'Second', valueString: '{{test.expression}}' }
          ]
        }.to_json
        run(input_template_test, client_id:, qp_response_template: template_with_duplicates)

        fhirpath_stub = stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'string', element: 'value' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(fhirpath_stub).to have_been_requested.once
      end

      it 'calls the FHIRPath service only once for duplicate tokens even when the result is empty' do
        template_with_duplicates = {
          resourceType: 'Parameters',
          parameter: [
            { name: 'First', valueString: '{{test.expression}}' },
            { name: 'Second', valueString: '{{test.expression}}' }
          ]
        }.to_json
        run(input_template_test, client_id:, qp_response_template: template_with_duplicates)

        fhirpath_stub = stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        expect(fhirpath_stub).to have_been_requested.once
      end

      it 'replaces each unique token expression independently with its own FHIRPath result' do
        template_with_two_tokens = {
          resourceType: 'Parameters',
          parameter: [
            { name: 'First', valueString: '{{first.expression}}' },
            { name: 'Second', valueString: '{{second.expression}}' }
          ]
        }.to_json
        run(input_template_test, client_id:, qp_response_template: template_with_two_tokens)

        # stub returns 'first-value' on the first call, 'second-value' on the second
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          { status: 200, body: [{ type: 'string', element: 'first-value' }].to_json,
            headers: { 'Content-Type' => 'application/json' } },
          { status: 200, body: [{ type: 'string', element: 'second-value' }].to_json,
            headers: { 'Content-Type' => 'application/json' } }
        )
        post_with_token

        expect(last_response.status).to eq(200)
        params = JSON.parse(last_response.body)['parameter']
        expect(params.find { |p| p['name'] == 'First' }['valueString']).to eq('first-value')
        expect(params.find { |p| p['name'] == 'Second' }['valueString']).to eq('second-value')
      end

      it 'does not error when the FHIRPath result element is an Array or Hash (complex type filtered to empty)' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200,
          body: [{ type: 'FHIR.Coding', element: { system: 'http://example.com', code: 'abc' } }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_with_token

        # The complex element is filtered to nil and joined as "", which the FHIR serializer
        # strips (FHIR forbids empty strings), so valueString is absent from the output.
        expect(last_response.status).to eq(200)
        params = JSON.parse(last_response.body)['parameter']
        expect(params.first['name']).to eq('TestParam')
        expect(params.first['valueString']).to be_nil
      end

      it 'returns 400 with OperationOutcome when FHIRPath returns 2xx with a non-JSON body (input template)' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: 'not json at all'
        )
        post_with_token

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 500 with OperationOutcome when FHIRPath returns 2xx with a non-JSON body (fixture template)' do
        fixture_json = { resourceType: 'Parameters',
                         parameter: [{ name: 'TestParam', valueString: '{{test.expression}}' }] }.to_json
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(end_with('fhirpath_fixture.json')).and_return(fixture_json)
        run(fhirpath_fixture_test, client_id:)

        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: 'not json at all'
        )
        post_with_token

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end
    end

    context 'when using a fixture-based response template' do
      it 'returns 200 with the fixture Parameters as the response body' do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(end_with('questionnaire_package_request_parameters_example.json'))
          .and_return(valid_parameters_template_json)
        run(parameters_fixture_test, client_id:)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('Parameters')
      end

      it 'returns 500 with OperationOutcome when the fixture resource is not a Parameters' do
        run(bundle_fixture_test, client_id:)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 500 with OperationOutcome when the fixture file does not exist' do
        run(missing_fixture_test, client_id:)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 500 with OperationOutcome when the fixture is valid JSON but not a FHIR resource' do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(end_with('non_fhir.json')).and_return('{"foo": "bar"}')
        run(non_fhir_fixture_test, client_id:)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(500)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end
    end

    context 'when using an input-based response template' do
      it 'returns 200 with the parsed input as the fhir+json Parameters body' do
        run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(200)
        expect(last_response.headers['Content-Type']).to include('application/fhir+json')
        expect(JSON.parse(last_response.body)['resourceType']).to eq('Parameters')
      end
    end

    # -------------------------------------------------------------------
    # Pre-wait validation of the qp_response_template input
    #
    # The wait test (DTRFullEHRV220InteractionWaitTest) validates an input-based
    # qp_response_template *before* calling wait(), so a bad template fails the wait test
    # itself rather than surfacing later as an HTTP error the first time the client hits the
    # mock endpoint.
    # -------------------------------------------------------------------

    context 'when validating the qp_response_template input before the wait' do
      it 'fails before waiting when no input value is provided' do
        result = run(input_template_test, client_id:)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('No response template provided')
      end

      it 'fails before waiting when the input is valid JSON but not a FHIR resource' do
        result = run(input_template_test, client_id:, qp_response_template: '{"foo": "bar"}')

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('must contain a Parameters resource')
      end

      it 'fails before waiting when the input is a non-Parameters FHIR resource' do
        bundle_json = FHIR::Bundle.new(type: 'collection').to_json
        result = run(input_template_test, client_id:, qp_response_template: bundle_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('must contain a Parameters resource')
      end

      it 'fails before waiting when the input template is itself a FHIR OperationOutcome' do
        oo_json = FHIR::OperationOutcome.new(
          issue: [FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'invalid')]
        ).to_json
        result = run(input_template_test, client_id:, qp_response_template: oo_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('must contain a Parameters resource')
      end

      it 'proceeds to wait when the input is a valid Parameters resource' do
        result = run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)

        expect(result.result).to eq('wait')
      end
    end

    context 'when qp_single_use is enabled' do
      # count_previous_requests filters by URL; Rack::Test omits REQUEST_PATH so the stored
      # URL has no path and the filter never matches. Set it explicitly so the count works.
      def post_with_token
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => server_endpoint)
      end

      before do
        run(single_use_test, client_id:, qp_response_template: valid_parameters_template_json)
      end

      it 'returns 200 on the first request' do
        post_with_token

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('Parameters')
      end

      it 'returns 400 with OperationOutcome on the second request' do
        post_with_token # first request — succeeds
        post_with_token # second request — single-use limit exceeded

        expect(last_response.status).to eq(400)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to include('only once')
      end

      it 'does not block subsequent requests when qp_single_use is not set' do
        run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)
        post_with_token
        post_with_token

        expect(last_response.status).to eq(200)
      end

      it 'does not count a 401 (expired token) response toward the single-use limit' do
        expired_token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)
        header('Authorization', "Bearer #{expired_token}")
        post(server_endpoint, valid_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => server_endpoint)
        expect(last_response.status).to eq(401)

        post_with_token
        expect(last_response.status).to eq(200)
      end

      it 'does not count a 400 (non-Parameters request body) response toward the single-use limit' do
        # Sending an OperationOutcome as the $questionnaire-package body causes request_parameters
        # to be an OO, which short-circuits response_body to return 400. Verify the slot is
        # still available for the next valid request.
        oo_body = FHIR::OperationOutcome.new(
          issue: [FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'invalid')]
        ).to_json
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, oo_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => server_endpoint)
        expect(last_response.status).to eq(400)

        post_with_token
        expect(last_response.status).to eq(200)
      end
    end

    # -------------------------------------------------------------------
    # Supporting Libraries and ValueSets
    #
    # Libraries and ValueSets from the configured Bundles are added to each package bundle when
    # its Questionnaires reference them, along with the Libraries those depend on.
    # -------------------------------------------------------------------

    context 'when supporting Library and ValueSet Bundles are configured' do
      let(:main_library_url) { 'https://madie.cms.gov/Library/InfernoDTRSampleCQLLibrary' }
      let(:burrito_library_canonical) { 'https://madie.cms.gov/Library/InfernoDTRSampleBurritoCQLLibrary|0.0.000' }
      let(:fhir_helpers_url) { 'http://hl7.org/fhir/uv/cql/Library/FHIRHelpers' }
      let(:burger_type_url) { 'https://inferno.healthit.gov/test-kits/davinci-dtr/ValueSet/burger-type' }
      let(:libraries_fixture) { 'cql_and_value_sets/cql_and_value_sets_libraries.json' }

      let(:supporting_fixture_test) do
        Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
          id :dtr_full_ehr_v220_qp_endpoint_spec_supporting_fixture_test
          input :qp_response_template, optional: true
          config options: {
            qp_response_template_input: 'qp_response_template',
            library_bundle_fixture: 'cql_and_value_sets/cql_and_value_sets_libraries.json',
            value_set_bundle_fixture: 'cql_and_value_sets/cql_and_value_sets_value_sets.json',
            dtr_workflow_tag: nil
          }
        end
      end

      let(:supporting_input_test) do
        Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
          id :dtr_full_ehr_v220_qp_endpoint_spec_supporting_input_test
          input :qp_response_template, optional: true
          input :library_bundle, optional: true
          config options: {
            qp_response_template_input: 'qp_response_template',
            library_bundle_input: 'library_bundle',
            dtr_workflow_tag: nil
          }
        end
      end

      # References the main library from the Questionnaire, the burger-type ValueSet from an
      # item's answerValueSet, and the burrito library from an include-resource extension.
      let(:referencing_questionnaire) do
        FHIR.from_contents({
          resourceType: 'Questionnaire',
          url: 'urn:inferno:dtr-test-kit:supporting-resources',
          status: 'draft',
          extension: [{ url: 'http://hl7.org/fhir/StructureDefinition/cqf-library', valueCanonical: main_library_url }],
          item: [
            { linkId: 'G', type: 'group', item: [
              { linkId: 'G.1', type: 'choice', answerValueSet: burger_type_url },
              { linkId: 'G.2', type: 'string',
                extension: [{ url: include_resource_url, valueCanonical: burrito_library_canonical }] }
            ] }
          ]
        }.to_json)
      end

      def package_template(resources)
        FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'packagebundle',
              resource: FHIR::Bundle.new(
                type: 'collection',
                entry: resources.map { |resource| FHIR::Bundle::Entry.new(resource:) }
              )
            )
          ]
        ).to_json
      end

      def response_bundle_resources
        JSON.parse(last_response.body)['parameter'].first['resource']['entry'].map { |entry| entry['resource'] }
      end

      def response_supporting_canonicals
        response_bundle_resources.reject { |resource| resource['resourceType'] == 'Questionnaire' }
          .map { |resource| "#{resource['resourceType']}|#{resource['url']}" }
      end

      it 'adds referenced Libraries and ValueSets and the Libraries they depend on' do
        run(supporting_fixture_test, client_id:, qp_response_template: package_template([referencing_questionnaire]))
        post_with_token

        expect(last_response.status).to eq(200)
        expect(response_supporting_canonicals).to contain_exactly(
          "Library|#{main_library_url}",
          "Library|#{fhir_helpers_url}",
          "Library|#{burrito_library_canonical.split('|').first}",
          "ValueSet|#{burger_type_url}"
        )
      end

      it 'does not duplicate a Library already in the package bundle but still adds its dependencies' do
        main_library = FHIR::Library.new(id: 'main', url: main_library_url, version: '0.0.000', status: 'active',
                                         relatedArtifact: [FHIR::RelatedArtifact.new(
                                           type: 'depends-on', resource: "#{fhir_helpers_url}|4.0.1"
                                         )])
        run(supporting_fixture_test, client_id:,
                                     qp_response_template: package_template([referencing_questionnaire, main_library]))
        post_with_token

        expect(response_supporting_canonicals.count("Library|#{main_library_url}")).to eq(1)
        expect(response_supporting_canonicals).to include("Library|#{fhir_helpers_url}")
      end

      it 'strips the include-resource extension from the returned Questionnaire items' do
        run(supporting_fixture_test, client_id:, qp_response_template: package_template([referencing_questionnaire]))
        post_with_token

        questionnaire = response_bundle_resources.find { |resource| resource['resourceType'] == 'Questionnaire' }
        item_extension_urls = questionnaire['item'].first['item'].flat_map { |item| item.fetch('extension', []) }
          .map { |ext| ext['url'] }
        expect(item_extension_urls).to_not include(include_resource_url)
      end

      it 'adds Libraries from a Bundle provided in an input' do
        library_bundle = File.read(File.join(__dir__, '..', '..', 'lib', 'davinci_dtr_test_kit', 'full_ehr',
                                             'fixtures', libraries_fixture))
        run(supporting_input_test, client_id:,
                                   qp_response_template: package_template([referencing_questionnaire]),
                                   library_bundle:)
        post_with_token

        expect(last_response.status).to eq(200)
        expect(response_supporting_canonicals).to include("Library|#{main_library_url}")
        expect(response_supporting_canonicals).to_not include("ValueSet|#{burger_type_url}")
      end

      it 'adds nothing when the optional Bundle input is empty' do
        run(supporting_input_test, client_id:, qp_response_template: package_template([referencing_questionnaire]))
        post_with_token

        expect(last_response.status).to eq(200)
        expect(response_supporting_canonicals).to be_empty
      end

      it 'fails before waiting when a supporting resource input is not a Bundle' do
        result = run(supporting_input_test, client_id:,
                                            qp_response_template: package_template([referencing_questionnaire]),
                                            library_bundle: FHIR::Library.new(status: 'active').to_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('must contain a Bundle resource')
      end

      context 'when a Library has dependencies only in its ELM includes' do
        let(:dependent_url) { 'https://example.org/Library/Dependent' }
        let(:helper_url) { 'https://example.org/Library/Helper' }
        let(:unversioned_url) { 'https://example.org/Library/Unversioned' }
        # Dependent's ELM includes Helper (versioned), Unversioned (no version), and an include with
        # no namespace, which can't be mapped to a url.
        let(:library_bundle) do
          includes = [
            { localIdentifier: 'Helper', path: 'https://example.org/Helper', version: '1.0.0' },
            { localIdentifier: 'Unversioned', path: 'https://example.org/Unversioned' },
            { localIdentifier: 'NoNamespace', path: 'NoNamespace', version: '1.0.0' }
          ]
          FHIR::Bundle.new(
            type: 'collection',
            entry: [library(dependent_url, content: [elm_content(includes)]), library(helper_url),
                    library(helper_url, '2.0.0'), library(unversioned_url, '3.0.0')]
              .map { |resource| FHIR::Bundle::Entry.new(resource:) }
          ).to_json
        end
        let(:dependent_questionnaire) do
          FHIR::Questionnaire.new(
            url: 'urn:inferno:dtr-test-kit:elm-includes', status: 'draft',
            extension: [FHIR::Extension.new(url: 'http://hl7.org/fhir/StructureDefinition/cqf-library',
                                            valueCanonical: dependent_url)]
          )
        end

        def elm_content(includes)
          FHIR::Attachment.new(contentType: 'application/elm+json',
                               data: Base64.strict_encode64({ library: { includes: { def: includes } } }.to_json))
        end

        def library(url, version = '1.0.0', content: [])
          FHIR::Library.new(id: url.split('/').last, url:, version:, status: 'active',
                            type: { coding: [{ code: 'logic-library' }] }, content:)
        end

        def response_libraries
          response_bundle_resources.select { |resource| resource['resourceType'] == 'Library' }
            .map { |resource| "#{resource['url']}|#{resource['version']}" }
        end

        it 'adds the Libraries the ELM includes, using the include version when there is one' do
          run(supporting_input_test, client_id:,
                                     qp_response_template: package_template([dependent_questionnaire]),
                                     library_bundle:)
          post_with_token

          expect(last_response.status).to eq(200)
          expect(response_libraries).to contain_exactly("#{dependent_url}|1.0.0", "#{helper_url}|1.0.0",
                                                        "#{unversioned_url}|3.0.0")
        end
      end

      context 'when deciding whether to include ValueSet expansions' do
        let(:toppings_url) { 'https://inferno.healthit.gov/test-kits/davinci-dtr/ValueSet/toppings' }
        let(:expanded_marker_url) { DaVinciDTRTestKit::InfernoControlExtensions::INCLUDE_VALUE_SET_EXPANDED_URL }
        let(:expansion) do
          FHIR::ValueSet::Expansion.new(
            timestamp: '2026-10-30T00:00:00Z',
            contains: [FHIR::ValueSet::Expansion::Contains.new(system: 'https://example.org', code: 'a')]
          )
        end

        # In the fixture Bundle, burger-type is marked to include its expansion and toppings is not.
        let(:value_set_questionnaire) do
          FHIR.from_contents({
            resourceType: 'Questionnaire',
            url: 'urn:inferno:dtr-test-kit:value-set-expansions',
            status: 'draft',
            item: [
              { linkId: 'Q1', type: 'choice', answerValueSet: burger_type_url },
              { linkId: 'Q2', type: 'choice', answerValueSet: toppings_url }
            ]
          }.to_json)
        end

        def response_value_set(url)
          response_bundle_resources.find { |resource| resource['resourceType'] == 'ValueSet' && resource['url'] == url }
        end

        def template_value_set(id, marker_value = nil)
          marker = FHIR::Extension.new(url: expanded_marker_url, valueBoolean: marker_value)
          extension = marker_value.nil? ? [] : [marker]
          FHIR::ValueSet.new(id:, url: "https://example.org/ValueSet/#{id}", status: 'active', extension:, expansion:)
        end

        it 'includes the expansion only for Bundle ValueSets marked to include it' do
          run(supporting_fixture_test, client_id:, qp_response_template: package_template([value_set_questionnaire]))
          post_with_token

          expect(response_value_set(burger_type_url)['expansion']).to be_present
          expect(response_value_set(toppings_url)).to be_present
          expect(response_value_set(toppings_url)).to_not have_key('expansion')
          expect(last_response.body).to_not include(expanded_marker_url)
        end

        it 'does not change the configured Bundle when removing an expansion' do
          run(supporting_fixture_test, client_id:, qp_response_template: package_template([value_set_questionnaire]))
          post_with_token

          fixture = DaVinciDTRTestKit::FixtureLoader.instance['cql_and_value_sets/cql_and_value_sets_value_sets.json']
          toppings = fixture.entry.map(&:resource).find { |resource| resource.url == toppings_url }
          expect(toppings.expansion).to be_present
          expect(toppings.extension.map(&:url)).to include(expanded_marker_url)
        end

        it 'returns template ValueSets as written, ignoring the include-value-set-expanded extension' do
          resources = [value_set_questionnaire, template_value_set('unmarked'),
                       template_value_set('marked-false', false), template_value_set('marked-true', true)]
          run(supporting_input_test, client_id:, qp_response_template: package_template(resources))
          post_with_token

          expect(response_value_set('https://example.org/ValueSet/unmarked')['expansion']).to be_present
          expect(response_value_set('https://example.org/ValueSet/marked-false')['expansion']).to be_present
          expect(response_value_set('https://example.org/ValueSet/marked-true')['expansion']).to be_present
          expect(last_response.body).to_not include(expanded_marker_url)
        end
      end
    end

    # -------------------------------------------------------------------
    # Questionnaires built from $next-question templates
    # -------------------------------------------------------------------

    context 'when package Questionnaires are built from $next-question templates' do
      let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate" }
      let(:use_template_url) { DaVinciDTRTestKit::InfernoControlExtensions::USE_NEXT_QUESTION_TEMPLATE_URL }
      let(:cql_template_url) do
        'https://inferno.healthit.gov/test-kits/davinci-dtr/Questionnaire/inferno-cql-and-value-sets-adaptive-questionnaire'
      end

      let(:cql_fixture_test) do
        Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
          id :dtr_full_ehr_v220_qp_endpoint_spec_cql_fixture_test
          config options: {
            qp_response_template_fixture:
              'cql_and_value_sets/cql_and_value_sets_questionnaire_package_response.json',
            nq_questionnaire_template_fixture:
              'cql_and_value_sets/cql_and_value_sets_adaptive_next_question_template.json',
            library_bundle_fixture: 'cql_and_value_sets/cql_and_value_sets_libraries.json',
            value_set_bundle_fixture: 'cql_and_value_sets/cql_and_value_sets_value_sets.json',
            dtr_workflow_tag: nil
          }
        end
      end

      # The CQL package fixture with the dinner $next-question template, which it doesn't reference.
      let(:mismatched_fixture_test) do
        Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
          id :dtr_full_ehr_v220_qp_endpoint_spec_mismatched_template_fixture_test
          config options: {
            qp_response_template_fixture:
              'cql_and_value_sets/cql_and_value_sets_questionnaire_package_response.json',
            nq_questionnaire_template_fixture: 'dinner_adaptive/dinner_order_adaptive_next_question_template.json',
            dtr_workflow_tag: nil
          }
        end
      end

      let(:templates_input_test) do
        Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
          id :dtr_full_ehr_v220_qp_endpoint_spec_templates_input_test
          input :qp_response_template, optional: true
          input :nq_questionnaire_template, optional: true
          config options: {
            qp_response_template_input: 'qp_response_template',
            nq_questionnaire_template_input: 'nq_questionnaire_template',
            dtr_workflow_tag: nil
          }
        end
      end

      let(:placeholder_template_json) do
        FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'packagebundle',
              resource: FHIR::Bundle.new(
                type: 'collection',
                entry: [FHIR::Bundle::Entry.new(
                  resource: FHIR::Questionnaire.new(
                    extension: [FHIR::Extension.new(url: use_template_url,
                                                    valueCanonical: 'https://example.org/Questionnaire/adaptive')]
                  )
                )]
              )
            )
          ]
        ).to_json
      end

      def nq_template_json(url)
        FHIR::Questionnaire.new(url:, status: 'draft').to_json
      end

      def package_resources
        JSON.parse(last_response.body)['parameter'].first['resource']['entry'].map { |entry| entry['resource'] }
      end

      it 'builds the CQL and ValueSets package from the fixtures' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'dateTime', element: '2026-10-28T12:00:00Z' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        run(cql_fixture_test, client_id:)
        post_with_token

        expect(last_response.status).to eq(200)
        questionnaire = package_resources.find { |resource| resource['resourceType'] == 'Questionnaire' }
        expect(questionnaire['url']).to eq(cql_template_url)
        expect(questionnaire['item'].map { |item| item['linkId'] }).to eq(['HIDDEN-1'])
        expect(questionnaire['item'].first['item'].map { |item| item['linkId'] })
          .to eq(['HIDDEN-1.1', 'HIDDEN-1.2', 'HIDDEN-1.3', 'HIDDEN-1.4'])

        response = package_resources.find { |resource| resource['resourceType'] == 'QuestionnaireResponse' }
        expect(response['contained'].first['url']).to eq(cql_template_url)
        expect(response['status']).to eq('in-progress')
        expect(response['questionnaire']).to eq("##{response['contained'].first['id']}")

        library_urls = package_resources.select { |resource| resource['resourceType'] == 'Library' }
          .map { |library| library['url'] }
        expect(library_urls).to contain_exactly('https://madie.cms.gov/Library/InfernoDTRSampleCQLLibrary',
                                                'http://hl7.org/fhir/uv/cql/Library/FHIRHelpers')

        DaVinciDTRTestKit::InfernoControlExtensions::ALL_URLS.each do |url|
          expect(last_response.body).to_not include(url)
        end
      end

      it 'returns 500 when a fixture placeholder matches no $next-question template' do
        run(mismatched_fixture_test, client_id:)
        post_with_token

        expect(last_response.status).to eq(500)
        expect(last_response.body).to include('No $next-question template Questionnaire matches')
      end

      it 'fails before waiting when an input placeholder matches no $next-question template' do
        result = run(templates_input_test, client_id:,
                                           qp_response_template: placeholder_template_json,
                                           nq_questionnaire_template: nq_template_json('https://example.org/other'))

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('no $next-question template Questionnaire has that url')
      end

      it 'builds the Questionnaire from a $next-question template provided in an input' do
        run(templates_input_test, client_id:,
                                  qp_response_template: placeholder_template_json,
                                  nq_questionnaire_template: nq_template_json('https://example.org/Questionnaire/adaptive'))
        post_with_token

        expect(last_response.status).to eq(200)
        expect(package_resources.first['url']).to eq('https://example.org/Questionnaire/adaptive')
      end
    end

    context 'when the template uses legacy urn:inferno extension urls' do
      let(:legacy_range_template) do
        FHIR.from_contents({
          resourceType: 'Parameters',
          parameter: [
            { name: 'First', extension: [{ url: 'urn:inferno:dtr:request-range', valueString: '1' }],
              resource: { resourceType: 'Bundle', type: 'collection' } },
            { name: 'Second', extension: [{ url: 'urn:inferno:dtr:request-range', valueString: '2' }],
              resource: { resourceType: 'Bundle', type: 'collection' } }
          ]
        }.to_json).to_json
      end

      it 'still applies and removes them' do
        run(input_template_test, client_id:, qp_response_template: legacy_range_template)
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json',
                                                  'REQUEST_PATH' => server_endpoint)

        expect(param_names).to eq(['First'])
        expect(last_response.body).to_not include('urn:inferno:dtr:request-range')
      end
    end
  end
end
