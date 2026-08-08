require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/interaction_wait_test'

RSpec.describe DaVinciDTRTestKit::MockPayer::FullEHRV220NextQuestionEndpoint, :request do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:suite) { Inferno::Repositories::TestSuites.new.find(suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:client_id) { 'test_client_id' }
  let(:qp_server_endpoint) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }
  let(:nq_server_endpoint) { "/custom/#{suite_id}/fhir/Questionnaire/$next-question" }

  let(:valid_qp_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
  end

  # Initial $next-question request: Parameters wrapping an in-progress QR whose contained
  # Questionnaire has url 'urn:inferno:dtr-test-kit:dinner-order-adaptive' and the adaptive
  # extension. This matches the adaptive questionnaire used in the QP pre-staging helpers below.
  let(:valid_nq_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_initial_input_params_conformant.json'))
  end

  # A $questionnaire-package response template that returns a single adaptive questionnaire.
  # The questionnaire URL matches the contained questionnaire in valid_nq_request_body, so the
  # NQ endpoint can find and validate the questionnaire in the QP request history.
  let(:adaptive_questionnaire_package_json) do
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [
              FHIR::Bundle::Entry.new(
                resource: FHIR::Questionnaire.new(
                  id: 'DinnerOrderAdaptive',
                  url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
                  status: 'draft',
                  extension: [
                    FHIR::Extension.new(
                      url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                      valueBoolean: true
                    )
                  ]
                )
              )
            ]
          )
        )
      ]
    ).to_json
  end

  # Same URL as the adaptive package but without the adaptive extension — used to exercise the
  # "questionnaire found but not adaptive" validation path.
  let(:non_adaptive_questionnaire_package_json) do
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(
          name: 'packagebundle',
          resource: FHIR::Bundle.new(
            type: 'collection',
            entry: [
              FHIR::Bundle::Entry.new(
                resource: FHIR::Questionnaire.new(
                  url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
                  status: 'draft'
                )
              )
            ]
          )
        )
      ]
    ).to_json
  end

  # A minimal NQ response template: one unconditional, optional item so the happy path does not
  # need the FHIRPath service and no completion logic fires.
  let(:valid_nq_questionnaire_template_json) do
    FHIR::Questionnaire.new(
      status: 'draft',
      item: [
        FHIR::Questionnaire::Item.new(linkId: 'Q1', text: 'Question 1', type: 'string', required: false)
      ]
    ).to_json
  end

  # Each subclass of DTRFullEHRV220InteractionWaitTest sets the config options the endpoint
  # reads from test.config.options. This lets each test exercise a distinct configuration
  # path without suite navigation or response stubs.

  # No NQ template configured, but has QP template so QP pre-staging still succeeds.
  let(:no_nq_template_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_nq_endpoint_spec_no_nq_template
      input :qp_response_template, optional: true
      config options: { qp_response_template_input: 'qp_response_template', dtr_workflow_tag: nil }
    end
  end

  # NQ fixture template pointing to the adaptive dinner questionnaire fixture (valid Questionnaire).
  let(:nq_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_nq_endpoint_spec_fixture
      input :qp_response_template, optional: true
      config options: {
        qp_response_template_input: 'qp_response_template',
        nq_questionnaire_template_fixture: 'dinner_adaptive/dinner_order_adaptive_next_question_template.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # NQ fixture template pointing to a Parameters resource (not a Questionnaire).
  let(:non_questionnaire_nq_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_nq_endpoint_spec_non_questionnaire_fixture
      input :qp_response_template, optional: true
      config options: {
        qp_response_template_input: 'qp_response_template',
        nq_questionnaire_template_fixture: 'dinner_adaptive/parameters_questionnaire_dinner_order_adaptive.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # NQ fixture template pointing to a nonexistent file.
  let(:missing_nq_fixture_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_nq_endpoint_spec_missing_fixture
      input :qp_response_template, optional: true
      config options: {
        qp_response_template_input: 'qp_response_template',
        nq_questionnaire_template_fixture: 'nonexistent/fixture.json',
        dtr_workflow_tag: nil
      }
    end
  end

  # NQ input template: both QP and NQ templates come from user-supplied inputs.
  let(:nq_input_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_nq_endpoint_spec_input
      input :qp_response_template, optional: true
      input :nq_questionnaire_template, optional: true
      config options: {
        qp_response_template_input: 'qp_response_template',
        nq_questionnaire_template_input: 'nq_questionnaire_template',
        dtr_workflow_tag: nil
      }
    end
  end

  # NQ input template with an additional dtr_workflow tag applied to the request.
  let(:workflow_tagged_test) do
    Class.new(DaVinciDTRTestKit::DTRFullEHRV220InteractionWaitTest) do
      id :dtr_full_ehr_v220_nq_endpoint_spec_workflow_tagged
      input :qp_response_template, optional: true
      input :nq_questionnaire_template, optional: true
      config options: {
        qp_response_template_input: 'qp_response_template',
        nq_questionnaire_template_input: 'nq_questionnaire_template',
        dtr_workflow_tag: 'custom_workflow'
      }
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

  describe 'When responding' do
    # REQUEST_PATH must be set so Inferno stores a URL that includes the operation path segment.
    # Without it Rack::Test omits REQUEST_PATH and the stored URL has no path, causing the NQ
    # endpoint's $questionnaire-package lookup (req.url.include?('$questionnaire-package')) and
    # the request-range counter (req.url.include?('$next-question')) to never match.
    def post_qp_with_token
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(qp_server_endpoint, valid_qp_request_body,
           'CONTENT_TYPE' => 'application/json',
           'REQUEST_PATH' => qp_server_endpoint)
    end

    def post_nq_with_token
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, valid_nq_request_body,
           'CONTENT_TYPE' => 'application/json',
           'REQUEST_PATH' => nq_server_endpoint)
    end

    it 'returns 401 when the token has expired' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      expired_token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)
      header('Authorization', "Bearer #{expired_token}")
      post(nq_server_endpoint, valid_nq_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(401)
    end

    it 'sets the Access-Control-Allow-Origin header to * on every response' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, 'not valid fhir json', 'CONTENT_TYPE' => 'text/plain')

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'sets the Access-Control-Allow-Origin header on 401 (expired token) responses' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      expired_token = UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, -1)
      header('Authorization', "Bearer #{expired_token}")
      post(nq_server_endpoint, valid_nq_request_body, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(401)
      expect(last_response.headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'tags the request with CLIENT_NEXT_TAG' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)
      post_qp_with_token
      post_nq_with_token

      tagged = requests_repo.tagged_requests(test_session.id, [DaVinciDTRTestKit::CLIENT_NEXT_TAG])
      expect(tagged.length).to eq(1)
    end

    it 'also applies the dtr_workflow_tag option as an additional request tag' do
      run(workflow_tagged_test, client_id:,
                                qp_response_template: adaptive_questionnaire_package_json,
                                nq_questionnaire_template: valid_nq_questionnaire_template_json)
      post_qp_with_token
      post_nq_with_token

      tagged = requests_repo.tagged_requests(
        test_session.id,
        [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'custom_workflow']
      )
      expect(tagged.length).to eq(1)
    end

    # -------------------------------------------------------------------
    # Request body parsing
    # -------------------------------------------------------------------

    it 'returns 400 with OperationOutcome when the request body is not parseable as FHIR' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, 'not valid fhir json', 'CONTENT_TYPE' => 'text/plain')

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('does not contain valid')
    end

    it 'returns 400 with OperationOutcome when Parameters body has no questionnaire-response parameter' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      no_qr_param = FHIR::Parameters.new(
        parameter: [FHIR::Parameters::Parameter.new(name: 'other-param', valueString: 'foo')]
      ).to_json
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, no_qr_param, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('parameter:questionnaire-response')
    end

    it 'returns 400 with OperationOutcome when questionnaire-response.resource is not a QuestionnaireResponse' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      non_qr_param = FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: FHIR::Patient.new)
        ]
      ).to_json
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, non_qr_param, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('is not a QuestionnaireResponse')
    end

    it 'returns 400 with OperationOutcome when the request is a not a Parameters or QuestionnaireResponse resource' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, FHIR::Bundle.new(type: 'collection').to_json,
           'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('Wrong resource type submitted')
    end

    # -------------------------------------------------------------------
    # QuestionnaireResponse validation
    # -------------------------------------------------------------------

    it 'returns 400 with OperationOutcome when the QuestionnaireResponse has no contained Questionnaire' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      no_contained = FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'questionnaire-response',
            resource: FHIR::QuestionnaireResponse.new(status: 'in-progress')
          )
        ]
      ).to_json
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, no_contained, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('no contained Questionnaire resource')
    end

    it 'returns 400 with OperationOutcome when the contained Questionnaire has no URL' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)

      no_url = FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'questionnaire-response',
            resource: FHIR::QuestionnaireResponse.new(
              status: 'in-progress',
              contained: [FHIR::Questionnaire.new(id: 'Q1', status: 'draft')]
            )
          )
        ]
      ).to_json
      header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
      post(nq_server_endpoint, no_url, 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('must have a url')
    end

    it 'returns 400 with OperationOutcome when questionnaire was not returned in a $questionnaire-package response' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)
      # Intentionally skip QP pre-staging so no matching questionnaire exists in the history.
      post_nq_with_token

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('not returned by $questionnaire-package')
    end

    it 'returns 400 with OperationOutcome when the questionnaire from $questionnaire-package is not adaptive' do
      run(nq_input_test, client_id:,
                         qp_response_template: non_adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)
      post_qp_with_token
      post_nq_with_token

      expect(last_response.status).to eq(400)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to include('is not adaptive')
    end

    it 'recognizes the questionnaire as adaptive when the adaptive extension uses valueUri instead of valueBoolean' do
      uri_adaptive_package = FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'packagebundle',
            resource: FHIR::Bundle.new(
              type: 'collection',
              entry: [
                FHIR::Bundle::Entry.new(
                  resource: FHIR::Questionnaire.new(
                    url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
                    status: 'draft',
                    extension: [
                      FHIR::Extension.new(
                        url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                        valueUri: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'
                      )
                    ]
                  )
                )
              ]
            )
          )
        ]
      ).to_json

      run(nq_input_test, client_id:,
                         qp_response_template: uri_adaptive_package,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)
      post_qp_with_token
      post_nq_with_token

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
    end

    it 'returns 500 with OperationOutcome when no NQ response template source is configured' do
      run(no_nq_template_test, client_id:, qp_response_template: adaptive_questionnaire_package_json)
      post_qp_with_token
      post_nq_with_token

      expect(last_response.status).to eq(500)
      parsed = JSON.parse(last_response.body)
      expect(parsed['resourceType']).to eq('OperationOutcome')
      expect(parsed['issue'].first['details']['text']).to match(/No response template source indicated/)
    end

    # -------------------------------------------------------------------
    # Fixture-based response template
    # -------------------------------------------------------------------

    context 'when using a fixture-based response template' do
      let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate" }

      it 'returns 200 with the QuestionnaireResponse when the fixture is a valid Questionnaire' do
        run(nq_fixture_test, client_id:, qp_response_template: adaptive_questionnaire_package_json)
        post_qp_with_token
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end

      it 'returns 500 with OperationOutcome when the fixture resource is not a Questionnaire' do
        run(non_questionnaire_nq_fixture_test, client_id:,
                                               qp_response_template: adaptive_questionnaire_package_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(500)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to match(/Invalid.*response template fixture/)
      end

      it 'returns 500 with OperationOutcome when the fixture file does not exist' do
        run(missing_nq_fixture_test, client_id:, qp_response_template: adaptive_questionnaire_package_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(500)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to match(/File not found/)
      end

      it 'returns 500 with OperationOutcome when the FHIRPath service returns a non-2xx status ' \
         '(fixture-based template)' do
        run(nq_fixture_test, client_id:, qp_response_template: adaptive_questionnaire_package_json)
        post_qp_with_token
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 422, body: 'FHIRPath evaluation error'
        )
        post_nq_with_token

        expect(last_response.status).to eq(500)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to match(/FHIRPath service returned 422/)
      end
    end

    # -------------------------------------------------------------------
    # Input-based response template
    # -------------------------------------------------------------------

    context 'when using an input-based response template' do
      it 'returns 200 with the updated QuestionnaireResponse as the fhir+json response body' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(last_response.headers['Content-Type']).to include('application/fhir+json')
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end
    end

    # -------------------------------------------------------------------
    # Pre-wait validation of response template inputs
    #
    # The wait test (DTRFullEHRV220InteractionWaitTest) validates any input-based response
    # template *before* calling wait(), so a bad template fails the wait test itself rather than
    # surfacing later as an HTTP error the first time the client hits the mock endpoint.
    # -------------------------------------------------------------------

    context 'when validating response template inputs before the wait' do
      it 'fails before waiting when no nq_questionnaire_template_input value is provided' do
        result = run(nq_input_test, client_id:, qp_response_template: adaptive_questionnaire_package_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to match(/No response template provided/)
      end

      it 'fails before waiting when the nq_questionnaire_template_input is not valid JSON' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: adaptive_questionnaire_package_json,
                                    nq_questionnaire_template: 'not valid json')

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('does not contain valid JSON')
      end

      it 'fails before waiting when the nq_questionnaire_template_input is not a Questionnaire' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: adaptive_questionnaire_package_json,
                                    nq_questionnaire_template: FHIR::Bundle.new(type: 'collection').to_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('expected a Questionnaire')
      end

      it 'fails before waiting when the nq_questionnaire_template_input is an empty array' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: adaptive_questionnaire_package_json,
                                    nq_questionnaire_template: [].to_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('does not contain any Questionnaire')
      end

      it 'fails before waiting when any entry in the nq_questionnaire_template_input array ' \
         'is not a Questionnaire' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: adaptive_questionnaire_package_json,
                                    nq_questionnaire_template: [
                                      FHIR::Questionnaire.new(status: 'draft'),
                                      FHIR::Bundle.new(type: 'collection')
                                    ].to_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('expected a Questionnaire')
        expect(result.result_message).to include('index 1')
      end

      it 'fails before waiting when the qp_response_template_input is not a Parameters resource' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: FHIR::Bundle.new(type: 'collection').to_json,
                                    nq_questionnaire_template: valid_nq_questionnaire_template_json)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('must contain a Parameters resource')
      end

      it 'proceeds to wait when both response templates are valid' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: adaptive_questionnaire_package_json,
                                    nq_questionnaire_template: valid_nq_questionnaire_template_json)

        expect(result.result).to eq('wait')
      end

      it 'proceeds to wait when the nq_questionnaire_template_input is an array of valid Questionnaires' do
        result = run(nq_input_test, client_id:,
                                    qp_response_template: adaptive_questionnaire_package_json,
                                    nq_questionnaire_template: [
                                      FHIR::Questionnaire.new(status: 'draft'), FHIR::Questionnaire.new(status: 'draft')
                                    ].to_json)

        expect(result.result).to eq('wait')
      end
    end

    # -------------------------------------------------------------------
    # Array-of-Questionnaires input-based response template
    # -------------------------------------------------------------------

    context 'when the input-based response template is a JSON array of Questionnaires' do
      # Contained Questionnaire in valid_nq_request_body has url
      # 'urn:inferno:dtr-test-kit:dinner-order-adaptive' and no version (see comment above).
      let(:other_questionnaire_json) do
        FHIR::Questionnaire.new(
          url: 'urn:inferno:dtr-test-kit:other-questionnaire',
          status: 'draft',
          item: [FHIR::Questionnaire::Item.new(linkId: 'Other', text: 'Other question', type: 'string')]
        )
      end

      let(:matching_questionnaire_json) do
        FHIR::Questionnaire.new(
          url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
          status: 'draft',
          item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', text: 'Question 1', type: 'string', required: false)]
        )
      end

      def contained_item_link_ids
        JSON.parse(last_response.body)
          .fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
          &.fetch('item', [])
          &.map { |i| i['linkId'] } || []
      end

      it 'selects the Questionnaire in the array whose url matches the contained Questionnaire' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: [other_questionnaire_json, matching_questionnaire_json].to_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Q1')
        expect(contained_item_link_ids).to_not include('Other')
      end

      it 'finds the match regardless of its position in the array' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: [matching_questionnaire_json, other_questionnaire_json].to_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Q1')
      end

      it 'matches by url and version when the contained Questionnaire carries a version' do
        versioned_url = 'urn:inferno:dtr-test-kit:dinner-order-adaptive'
        adaptive_extension = FHIR::Extension.new(
          url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueBoolean: true
        )
        matching_versioned = FHIR::Questionnaire.new(
          url: versioned_url, version: '1.0', status: 'draft',
          item: [FHIR::Questionnaire::Item.new(linkId: 'V1', text: 'Correct version', type: 'string')]
        )
        wrong_version = FHIR::Questionnaire.new(
          url: versioned_url, version: '2.0', status: 'draft',
          item: [FHIR::Questionnaire::Item.new(linkId: 'V2', text: 'Wrong version', type: 'string')]
        )
        versioned_qp_json = FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'packagebundle',
              resource: FHIR::Bundle.new(
                type: 'collection',
                entry: [FHIR::Bundle::Entry.new(
                  resource: FHIR::Questionnaire.new(url: versioned_url, version: '1.0', status: 'draft',
                                                    extension: [adaptive_extension])
                )]
              )
            )
          ]
        ).to_json
        versioned_nq_body = FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'questionnaire-response',
              resource: FHIR::QuestionnaireResponse.new(
                status: 'in-progress',
                contained: [FHIR::Questionnaire.new(id: 'DinnerOrderAdaptive', url: versioned_url, version: '1.0',
                                                    status: 'draft', extension: [adaptive_extension])]
              )
            )
          ]
        ).to_json

        run(nq_input_test, client_id:,
                           qp_response_template: versioned_qp_json,
                           nq_questionnaire_template: [wrong_version, matching_versioned].to_json)
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(qp_server_endpoint, valid_qp_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => qp_server_endpoint)
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, versioned_nq_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('V1')
        expect(contained_item_link_ids).to_not include('V2')
      end

      it 'returns 400 with OperationOutcome when no Questionnaire in the array matches the contained Questionnaire' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: [other_questionnaire_json].to_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(400)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to include('No Questionnaire')
      end
    end

    # -------------------------------------------------------------------
    # FHIRPath inclusion criteria on template items
    # -------------------------------------------------------------------

    context 'when template items have FHIRPath inclusion criteria' do
      let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate" }

      let(:template_with_criteria) do
        FHIR.from_contents({
          resourceType: 'Questionnaire',
          status: 'draft',
          item: [
            { linkId: 'Unconditional', text: 'Always included', type: 'string' },
            { linkId: 'Conditional',
              text: 'Conditionally included',
              type: 'string',
              extension: [{ url: 'urn:inferno:dtr:inclusion-criteria',
                            valueExpression: { expression: 'true', language: 'text/fhirpath' } }] }
          ]
        }.to_json).to_json
      end

      before do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: template_with_criteria)
        post_qp_with_token
      end

      def contained_item_link_ids
        JSON.parse(last_response.body)
          .fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
          &.fetch('item', [])
          &.map { |i| i['linkId'] } || []
      end

      it 'includes the item when the FHIRPath expression evaluates to boolean true' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional', 'Conditional')
      end

      it 'strips the inclusion-criteria extension from an included item' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: true }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        contained_q = JSON.parse(last_response.body).fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
        conditional_item = contained_q&.fetch('item', [])&.find { |i| i['linkId'] == 'Conditional' }
        extension_urls = conditional_item&.fetch('extension', [])&.map { |e| e['url'] } || []
        expect(extension_urls).to_not include('urn:inferno:dtr:inclusion-criteria')
      end

      it 'excludes the item when the FHIRPath expression evaluates to boolean false' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'boolean', element: false }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional')
        expect(contained_item_link_ids).to_not include('Conditional')
      end

      it 'excludes the item when the FHIRPath expression returns an empty result set' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional')
        expect(contained_item_link_ids).to_not include('Conditional')
      end

      it 'includes the item when the FHIRPath expression returns a single non-boolean result' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'string', element: 'some-value' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional', 'Conditional')
      end

      it 'excludes the item when the FHIRPath expression returns multiple results' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 200, body: [{ type: 'string', element: 'some-value' },
                              { type: 'string', element: 'some-other-value' }].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional')
        expect(contained_item_link_ids).to_not include('Conditional')
      end

      it 'returns 400 with OperationOutcome when the FHIRPath service returns a non-2xx status ' \
         '(input-based template)' do
        stub_request(:post, /#{Regexp.quote(fhirpath_url)}/).to_return(
          status: 422, body: 'FHIRPath evaluation error'
        )
        post_nq_with_token

        expect(last_response.status).to eq(400)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to match(/FHIRPath service returned 422/)
      end
    end

    # -------------------------------------------------------------------
    # Request-range criteria on template items
    # -------------------------------------------------------------------

    context 'when template items have request-range criteria' do
      let(:template_with_range) do
        FHIR.from_contents({
          resourceType: 'Questionnaire',
          status: 'draft',
          item: [
            { linkId: 'Unconditional', text: 'Always included', type: 'string' },
            { linkId: 'RangeLimited',
              text: 'Range-limited',
              type: 'string',
              extension: [{ url: 'urn:inferno:dtr:request-range', valueString: '1' }] }
          ]
        }.to_json).to_json
      end

      before do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: template_with_range)
        post_qp_with_token
      end

      def contained_item_link_ids
        JSON.parse(last_response.body)
          .fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
          &.fetch('item', [])
          &.map { |i| i['linkId'] } || []
      end

      it 'includes the item on the first request (within range 1)' do
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional', 'RangeLimited')
      end

      it 'strips the request-range extension from an included item' do
        post_nq_with_token

        contained_q = JSON.parse(last_response.body).fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
        range_item = contained_q&.fetch('item', [])&.find { |i| i['linkId'] == 'RangeLimited' }
        extension_urls = range_item&.fetch('extension', [])&.map { |e| e['url'] } || []
        expect(extension_urls).to_not include('urn:inferno:dtr:request-range')
      end

      it 'excludes the item on the second request (outside range 1)' do
        post_nq_with_token # request 1 — within range 1
        post_nq_with_token # request 2 — outside range 1

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Unconditional')
        expect(contained_item_link_ids).to_not include('RangeLimited')
      end
    end

    # -------------------------------------------------------------------
    # Nested group item disclosure
    # -------------------------------------------------------------------

    context 'when template items are nested within a group' do
      # Group1 has Q1 (range "1") and Q2 (range "2"). On the first NQ call Group1 is new so it is
      # added along with Q1. On the second call Group1 already exists, so the endpoint must recurse
      # into its children and add Q2 rather than skipping the group entirely.
      let(:nested_group_template_json) do
        FHIR.from_contents({
          resourceType: 'Questionnaire',
          status: 'draft',
          item: [
            { linkId: 'Group1', type: 'group', item: [
              { linkId: 'Q1', type: 'string',
                extension: [{ url: 'urn:inferno:dtr:request-range', valueString: '1' }] },
              { linkId: 'Q2', type: 'string',
                extension: [{ url: 'urn:inferno:dtr:request-range', valueString: '2' }] }
            ] }
          ]
        }.to_json).to_json
      end

      # Second NQ call: QR whose contained Questionnaire already has Group1+Q1 (as if the client
      # echoed back the questionnaire state returned by the first $next-question response).
      def second_nq_request_body
        contained_q = FHIR::Questionnaire.new(
          id: 'DinnerOrderAdaptive',
          url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
          status: 'draft',
          item: [
            FHIR::Questionnaire::Item.new(
              linkId: 'Group1', type: 'group',
              item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string')]
            )
          ]
        )
        FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'questionnaire-response',
              resource: FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [contained_q])
            )
          ]
        ).to_json
      end

      def contained_item_link_ids
        JSON.parse(last_response.body)
          .fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
          &.fetch('item', [])
          &.map { |i| i['linkId'] } || []
      end

      def group1_child_link_ids
        contained_q = JSON.parse(last_response.body)
          .fetch('contained', [])
          .find { |r| r['resourceType'] == 'Questionnaire' }
        return [] unless contained_q

        group1 = contained_q.fetch('item', []).find { |i| i['linkId'] == 'Group1' }
        return [] unless group1

        group1.fetch('item', []).map { |i| i['linkId'] }
      end

      before do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: nested_group_template_json)
        post_qp_with_token
      end

      it 'adds a new group with its range-eligible child items on the first request' do
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(contained_item_link_ids).to include('Group1')
        expect(group1_child_link_ids).to include('Q1')
        expect(group1_child_link_ids).to_not include('Q2')
      end

      it 'adds new child items to an existing group on subsequent requests' do
        post_nq_with_token # request 1: Group1 + Q1 added

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, second_nq_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(group1_child_link_ids).to include('Q1', 'Q2')
      end
    end

    # -------------------------------------------------------------------
    # Questionnaire completion detection
    # -------------------------------------------------------------------

    context 'when computing questionnaire completion' do
      # Template with a single required item. The endpoint will add Q1 to the contained
      # Questionnaire on each call and then check whether every required item is answered.
      let(:required_item_template_json) do
        FHIR::Questionnaire.new(
          status: 'draft',
          item: [
            FHIR::Questionnaire::Item.new(linkId: 'Q1', text: 'Required question', type: 'string',
                                          required: true)
          ]
        ).to_json
      end

      # Builds a $next-question request body whose contained Questionnaire matches the
      # adaptive questionnaire pre-staged in the QP endpoint, optionally including a Q1 answer.
      def nq_request_body(with_answer:)
        qr = FHIR::QuestionnaireResponse.new(
          status: 'in-progress',
          contained: [
            FHIR::Questionnaire.new(
              id: 'DinnerOrderAdaptive',
              url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
              status: 'draft',
              extension: [
                FHIR::Extension.new(
                  url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                  valueBoolean: true
                )
              ]
            )
          ]
        )
        if with_answer
          qr.item = [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Q1',
              answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'My answer')]
            )
          ]
        end
        FHIR::Parameters.new(
          parameter: [FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: qr)]
        ).to_json
      end

      before do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: required_item_template_json)
        post_qp_with_token
      end

      # Like nq_request_body but the contained Questionnaire already has Q1 in its item list,
      # simulating a client that echoes back a questionnaire state from a prior NQ response.
      def nq_request_with_preexisting_q1(answered:)
        contained_q = FHIR::Questionnaire.new(
          id: 'DinnerOrderAdaptive',
          url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
          status: 'draft',
          extension: [
            FHIR::Extension.new(
              url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
              valueBoolean: true
            )
          ],
          item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
        )
        qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [contained_q])
        if answered
          qr.item = [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Q1',
              answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'My answer')]
            )
          ]
        end
        FHIR::Parameters.new(
          parameter: [FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: qr)]
        ).to_json
      end

      it 'keeps the QuestionnaireResponse status as in-progress when new questions are added, ' \
         'even if answers are present' do
        # Q1 is not yet in the contained questionnaire, so the endpoint adds it (@new_questions_added = true).
        # Even though Q1 is answered in the QR, completion must not fire when new questions were disclosed.
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, nq_request_body(with_answer: true),
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to eq('in-progress')
      end

      it 'sets the QuestionnaireResponse status to completed when all required items are pre-existing and answered' do
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, nq_request_with_preexisting_q1(answered: true),
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to eq('completed')
      end

      it 'sets the QuestionnaireResponse status to completed when the required item answer value is boolean false' do
        # Regression guard: answer_completed_and_valid? must use !nil? not .present? so that
        # false (a valid boolean answer) is not mistaken for a missing answer.
        # Q1 is pre-existing in the contained questionnaire so no new questions are added.
        false_answer_body = FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'questionnaire-response',
              resource: FHIR::QuestionnaireResponse.new(
                status: 'in-progress',
                contained: [
                  FHIR::Questionnaire.new(
                    id: 'DinnerOrderAdaptive',
                    url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
                    status: 'draft',
                    extension: [
                      FHIR::Extension.new(
                        url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                        valueBoolean: true
                      )
                    ],
                    item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
                  )
                ],
                item: [
                  FHIR::QuestionnaireResponse::Item.new(
                    linkId: 'Q1',
                    answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueBoolean: false)]
                  )
                ]
              )
            )
          ]
        ).to_json
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, false_answer_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to eq('completed')
      end

      it 'keeps the QuestionnaireResponse status as in-progress when required items are unanswered' do
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, nq_request_body(with_answer: false),
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to eq('in-progress')
      end
    end

    # -------------------------------------------------------------------
    # Nested required sub-items and completion
    # -------------------------------------------------------------------

    context 'when a required sub-item is nested within a group' do
      let(:nested_required_template_json) do
        FHIR::Questionnaire.new(
          status: 'draft',
          item: [
            FHIR::Questionnaire::Item.new(
              linkId: 'Group1', type: 'group',
              item: [
                FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)
              ]
            )
          ]
        ).to_json
      end

      # Builds a request whose contained Questionnaire already has Group1 > Q1(required),
      # simulating a client that echoed back questionnaire state from a prior NQ response.
      def nq_body_with_group_answer(answered:)
        contained_q = FHIR::Questionnaire.new(
          id: 'DinnerOrderAdaptive',
          url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
          status: 'draft',
          extension: [
            FHIR::Extension.new(
              url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
              valueBoolean: true
            )
          ],
          item: [
            FHIR::Questionnaire::Item.new(
              linkId: 'Group1', type: 'group',
              item: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)]
            )
          ]
        )
        qr = FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [contained_q])
        if answered
          qr.item = [
            FHIR::QuestionnaireResponse::Item.new(
              linkId: 'Group1',
              item: [
                FHIR::QuestionnaireResponse::Item.new(
                  linkId: 'Q1',
                  answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'My answer')]
                )
              ]
            )
          ]
        end
        FHIR::Parameters.new(
          parameter: [FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: qr)]
        ).to_json
      end

      before do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: nested_required_template_json)
        post_qp_with_token
      end

      it 'marks the QuestionnaireResponse as completed when the nested required sub-item is answered' do
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, nq_body_with_group_answer(answered: true),
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to eq('completed')
      end

      it 'keeps the QuestionnaireResponse as in-progress when the nested required sub-item is unanswered' do
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, nq_body_with_group_answer(answered: false),
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['status']).to eq('in-progress')
      end
    end

    # -------------------------------------------------------------------
    # Multi-QP request history
    # -------------------------------------------------------------------

    context 'when multiple $questionnaire-package responses are in the request history' do
      it 'finds the questionnaire when it appears in multiple QP responses' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)
        post_qp_with_token # first QP call
        post_qp_with_token # second QP call — stores a second response under the same result
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end

      it 'finds the questionnaire in a later packagebundle parameter within a single QP response' do
        # QP response with two packagebundle parameters: first bundle has a non-matching
        # questionnaire; second bundle has the adaptive dinner questionnaire.
        multi_bundle_template = FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'packagebundle',
              resource: FHIR::Bundle.new(
                type: 'collection',
                entry: [FHIR::Bundle::Entry.new(
                  resource: FHIR::Questionnaire.new(
                    url: 'urn:inferno:dtr-test-kit:other-questionnaire',
                    status: 'draft'
                  )
                )]
              )
            ),
            FHIR::Parameters::Parameter.new(
              name: 'packagebundle',
              resource: FHIR::Bundle.new(
                type: 'collection',
                entry: [FHIR::Bundle::Entry.new(
                  resource: FHIR::Questionnaire.new(
                    url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
                    status: 'draft',
                    extension: [FHIR::Extension.new(
                      url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                      valueBoolean: true
                    )]
                  )
                )]
              )
            )
          ]
        ).to_json

        run(nq_input_test, client_id:,
                           qp_response_template: multi_bundle_template,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)
        post_qp_with_token
        post_nq_with_token

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end

      it 'ignores $questionnaire-package responses with non-200 status codes when looking up the questionnaire' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)
        # Post a Bundle (not Parameters) to QP — endpoint returns 400; this request should be excluded from history
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(qp_server_endpoint, FHIR::Bundle.new(type: 'collection').to_json,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => qp_server_endpoint)
        expect(last_response.status).to eq(400)

        post_qp_with_token # valid QP request — status 200
        post_nq_with_token # NQ should find the questionnaire via the 200 response only

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end
    end

    # -------------------------------------------------------------------
    # Versioned canonical URL matching
    # -------------------------------------------------------------------

    context 'when the questionnaire has a versioned canonical URL' do
      let(:versioned_url) { 'urn:inferno:dtr-test-kit:dinner-order-adaptive' }
      let(:version) { '1.0' }

      let(:versioned_qp_json) do
        FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'packagebundle',
              resource: FHIR::Bundle.new(
                type: 'collection',
                entry: [
                  FHIR::Bundle::Entry.new(
                    resource: FHIR::Questionnaire.new(
                      url: versioned_url,
                      version: version,
                      status: 'draft',
                      extension: [
                        FHIR::Extension.new(
                          url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                          valueBoolean: true
                        )
                      ]
                    )
                  )
                ]
              )
            )
          ]
        ).to_json
      end

      # NQ request body whose contained questionnaire carries the same url|version.
      let(:versioned_nq_body) do
        FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'questionnaire-response',
              resource: FHIR::QuestionnaireResponse.new(
                status: 'in-progress',
                contained: [
                  FHIR::Questionnaire.new(
                    id: 'DinnerOrderAdaptive',
                    url: versioned_url,
                    version: version,
                    status: 'draft',
                    extension: [
                      FHIR::Extension.new(
                        url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                        valueBoolean: true
                      )
                    ]
                  )
                ]
              )
            )
          ]
        ).to_json
      end

      it 'matches the questionnaire using url|version when both sides carry a version' do
        run(nq_input_test, client_id:,
                           qp_response_template: versioned_qp_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(qp_server_endpoint, valid_qp_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => qp_server_endpoint)
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, versioned_nq_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end

      it 'returns 400 when the contained questionnaire version does not match the packaged questionnaire' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(qp_server_endpoint, valid_qp_request_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => qp_server_endpoint)
        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, versioned_nq_body,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(400)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to include('not returned by $questionnaire-package')
      end
    end

    # -------------------------------------------------------------------
    # Direct QuestionnaireResponse request body (not wrapped in Parameters)
    # -------------------------------------------------------------------

    context 'when the request body is a bare QuestionnaireResponse' do
      it 'returns 400 with OperationOutcome when the bare QuestionnaireResponse has no contained Questionnaire' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, FHIR::QuestionnaireResponse.new(status: 'in-progress').to_json,
             'CONTENT_TYPE' => 'application/json')

        expect(last_response.status).to eq(400)
        parsed = JSON.parse(last_response.body)
        expect(parsed['resourceType']).to eq('OperationOutcome')
        expect(parsed['issue'].first['details']['text']).to include('no contained Questionnaire resource')
      end

      it 'returns 200 with the updated QuestionnaireResponse' do
        run(nq_input_test, client_id:,
                           qp_response_template: adaptive_questionnaire_package_json,
                           nq_questionnaire_template: valid_nq_questionnaire_template_json)
        post_qp_with_token

        bare_qr = FHIR::QuestionnaireResponse.new(
          status: 'in-progress',
          contained: [
            FHIR::Questionnaire.new(
              id: 'DinnerOrderAdaptive',
              url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
              status: 'draft',
              extension: [
                FHIR::Extension.new(
                  url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                  valueBoolean: true
                )
              ]
            )
          ]
        ).to_json

        header('Authorization', "Bearer #{UDAPSecurityTestKit::MockUDAPServer.client_id_to_token(client_id, 5)}")
        post(nq_server_endpoint, bare_qr,
             'CONTENT_TYPE' => 'application/json',
             'REQUEST_PATH' => nq_server_endpoint)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
      end
    end

    it 'identifies the test run via the session_path query parameter when no Bearer token is present' do
      run(nq_input_test, client_id:,
                         qp_response_template: adaptive_questionnaire_package_json,
                         nq_questionnaire_template: valid_nq_questionnaire_template_json)
      post_qp_with_token

      post("#{nq_server_endpoint}?session_path=#{client_id}", valid_nq_request_body,
           'CONTENT_TYPE' => 'application/json',
           'REQUEST_PATH' => nq_server_endpoint)

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['resourceType']).to eq('QuestionnaireResponse')
    end
  end
end
