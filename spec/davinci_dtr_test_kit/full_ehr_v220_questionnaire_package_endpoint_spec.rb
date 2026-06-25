require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::MockPayer::FullEHRV220QuestionnairePackageEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:suite) { Inferno::Repositories::TestSuites.new.find(suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:client_id) { 'test_client_id' }
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
        qp_response_template_fixture: 'questionnaire_package_parameters_example.json',
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
              extension: [{ url: 'urn:inferno:dtr:inclusion-criteria',
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
        expect(extension_urls).to_not include('urn:inferno:dtr:inclusion-criteria')
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
              extension: [{ url: 'urn:inferno:dtr:request-range', valueString: range_string }],
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
        expect(extension_urls).to_not include('urn:inferno:dtr:request-range')
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
                { url: 'urn:inferno:dtr:inclusion-criteria',
                  valueExpression: { expression: 'true', language: 'text/fhirpath' } },
                { url: 'urn:inferno:dtr:request-range', valueString: '1-2' }
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
        allow(File).to receive(:read).with(end_with('questionnaire_package_parameters_example.json'))
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

      it 'returns 400 with OperationOutcome when no input value is provided' do
        run(input_template_test, client_id:)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(400)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to match(/No response template provided/)
      end

      it 'returns 400 with OperationOutcome when the input is valid JSON but not a FHIR resource' do
        run(input_template_test, client_id:, qp_response_template: '{"foo": "bar"}')

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 400 with OperationOutcome when the input is a non-Parameters FHIR resource' do
        bundle_json = FHIR::Bundle.new(type: 'collection').to_json
        run(input_template_test, client_id:, qp_response_template: bundle_json)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
      end

      it 'returns 400 with OperationOutcome when the input template is itself a FHIR OperationOutcome' do
        oo_json = FHIR::OperationOutcome.new(
          issue: [FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'invalid')]
        ).to_json
        run(input_template_test, client_id:, qp_response_template: oo_json)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(server_endpoint, valid_request_body, 'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('OperationOutcome')
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
        expect(parsed['issue'].first['details']['text']).to match(/only once/)
      end

      it 'does not block subsequent requests when qp_single_use is not set' do
        run(input_template_test, client_id:, qp_response_template: valid_parameters_template_json)
        post_with_token
        post_with_token

        expect(last_response.status).to eq(200)
      end

      it 'continues to return the template OperationOutcome on every request when the template is an OO' do
        # Template errors take priority over the single-use gate: the single-use check only
        # sits between the template-OO path and instantiate_template. When the template itself
        # is an OO (a test-configuration error), every request returns that OO unchanged.
        oo_json = FHIR::OperationOutcome.new(
          issue: [FHIR::OperationOutcome::Issue.new(severity: 'error', code: 'invalid')]
        ).to_json
        run(single_use_test, client_id:, qp_response_template: oo_json)

        post_with_token
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['issue'].first['code']).to eq('invalid')

        post_with_token
        expect(last_response.status).to eq(400)
        expect(JSON.parse(last_response.body)['issue'].first['code']).to eq('invalid')
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
  end
end
