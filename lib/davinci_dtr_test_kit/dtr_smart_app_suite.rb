require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'client_groups/resp_assist_device/dtr_smart_app_questionnaire_workflow_group'
require_relative 'client_groups/dinner_static/dtr_smart_app_questionnaire_workflow_group'
require_relative 'client_groups/dinner_adaptive/dtr_smart_app_questionnaire_workflow_group'
require_relative 'mock_payer'
require_relative 'mock_ehr'
require_relative 'version'

module DaVinciDTRTestKit
  class DTRSmartAppSuite < Inferno::TestSuite
    extend MockAuthServer
    extend MockEHR
    extend MockPayer

    id :dtr_smart_app
    title 'Da Vinci DTR SMART App Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_smart_app_suite_description_v201.md'))

    version VERSION

    links [
      {
        label: 'Report Issue',
        url: 'https://github.com/inferno-framework/davinci-dtr-test-kit/issues'
      },
      {
        label: 'Open Source',
        url: 'https://github.com/inferno-framework/davinci-dtr-test-kit'
      },
      {
        label: 'Download',
        url: 'https://github.com/inferno-framework/davinci-dtr-test-kit/releases'
      },
      {
        label: 'Implementation Guide',
        url: 'https://hl7.org/fhir/us/davinci-dtr/STU2/'
      }
    ]

    # Hl7 Validator Wrapper:
    fhir_resource_validator do
      igs 'hl7.fhir.us.davinci-dtr#2.0.1'

      exclude_message do |message|
        message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
      end
    end

    allow_cors QUESTIONNAIRE_PACKAGE_PATH, QUESTIONNAIRE_RESPONSE_PATH, FHIR_RESOURCE_PATH, FHIR_SEARCH_PATH,
               EHR_AUTHORIZE_PATH, EHR_TOKEN_PATH, JKWS_PATH, OPENID_CONFIG_PATH, NEXT_PATH

    def self.test_resumes?(test)
      !test.config.options[:accepts_multiple_requests]
    end

    route(:get, '/fhir/metadata', method(:metadata_handler))

    route(:get, SMART_CONFIG_PATH, method(:ehr_smart_config))
    route(:get, OPENID_CONFIG_PATH, method(:ehr_openid_config))

    route(:get, JKWS_PATH, method(:auth_server_jwks))

    record_response_route :get, EHR_AUTHORIZE_PATH, EHR_AUTHORIZE_TAG, method(:ehr_authorize),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_client_id_from_query_params(request)
    end

    record_response_route :post, EHR_AUTHORIZE_PATH, EHR_AUTHORIZE_TAG, method(:ehr_authorize),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_client_id_from_form_params(request)
    end

    record_response_route :post, EHR_TOKEN_PATH, 'dtr_smart_app_ehr_token', method(:ehr_token_response),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_client_id_from_token_request(request)
    end

    record_response_route :post, PAYER_TOKEN_PATH, 'dtr_smart_app_payer_token',
                          method(:payer_token_response) do |request|
      DTRSmartAppSuite.extract_client_id_from_client_assertion(request)
    end

    record_response_route :post, QUESTIONNAIRE_PACKAGE_PATH, QUESTIONNAIRE_PACKAGE_TAG,
                          method(:questionnaire_package_response), resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_client_id_from_bearer_token(request)
    end

    record_response_route :post, NEXT_PATH, CLIENT_NEXT_TAG, method(:client_questionnaire_next_response),
                          resumes: method(:test_resumes?) do |request|
      DTRSmartAppSuite.extract_client_id_from_bearer_token(request)
    end

    record_response_route :post, QUESTIONNAIRE_RESPONSE_PATH, 'dtr_smart_app_questionnaire_response',
                          method(:questionnaire_response_response) do |request|
      DTRSmartAppSuite.extract_client_id_from_bearer_token(request)
    end

    record_response_route :get, FHIR_RESOURCE_PATH, SMART_APP_EHR_REQUEST_TAG, method(:get_fhir_resource),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_client_id_from_bearer_token(request)
    end

    record_response_route :get, FHIR_SEARCH_PATH, SMART_APP_EHR_REQUEST_TAG, method(:get_fhir_resource),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_client_id_from_bearer_token(request)
    end

    resume_test_route :get, RESUME_PASS_PATH do |request|
      DTRSmartAppSuite.extract_client_id_from_query_params(request)
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      DTRSmartAppSuite.extract_client_id_from_query_params(request)
    end

    # TODO: Update based on SMART Launch changes. Do we even want to have this group now?
    # group from: :oauth2_authentication

    group do
      id :dtr_smart_app_basic_workflows
      title 'Basic Workflows'
      description %(
        Tests in this group validate that the client can complete basic DTR workflows
      )

      group from: :dtr_smart_app_static_dinner_questionnaire_workflow
      group from: :dtr_smart_app_adaptive_dinner_questionnaire_workflow
    end
    group do
      id :dtr_smart_app_questionnaire_functionality
      title 'Questionnaire Functionality Coverage'
      description %(
        Tests in this group validate that the client can complete additional DTR workflows
        covering additional must support features of questionnaires.
      )
      group from: :dtr_smart_app_questionnaire_workflow
    end
  end
end
