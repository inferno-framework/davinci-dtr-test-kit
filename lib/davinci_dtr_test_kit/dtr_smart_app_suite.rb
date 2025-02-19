require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'client_groups/resp_assist_device/dtr_smart_app_questionnaire_workflow_group'
require_relative 'client_groups/dinner_static/dtr_smart_app_questionnaire_workflow_group'
require_relative 'client_groups/dinner_adaptive/dtr_smart_app_questionnaire_workflow_group'
require_relative 'client_groups/custom_static/dtr_smart_app_custom_questionnaire_workflow_group'
require_relative 'endpoints/cors'
require_relative 'endpoints/mock_authorization'
require_relative 'endpoints/mock_authorization/authorize_endpoint'
require_relative 'endpoints/mock_authorization/token_endpoint'
require_relative 'endpoints/mock_payer/questionnaire_package_endpoint'
require_relative 'endpoints/mock_payer/next_question_endpoint'
require_relative 'endpoints/mock_ehr'
require_relative 'endpoints/mock_ehr/questionnaire_response_endpoint'
require_relative 'endpoints/mock_ehr/fhir_get_endpoint'
require_relative 'version'

module DaVinciDTRTestKit
  class DTRSmartAppSuite < Inferno::TestSuite
    extend CORS

    id :dtr_smart_app
    title 'Da Vinci DTR SMART App Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_smart_app_suite_description_v201.md'))

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

    # Authorization server
    route(:get, SMART_CONFIG_PATH, MockAuthorization.method(:ehr_smart_config))
    route(:get, OPENID_CONFIG_PATH, MockAuthorization.method(:ehr_openid_config))
    route(:get, JKWS_PATH, MockAuthorization.method(:jwks))
    suite_endpoint :get, EHR_AUTHORIZE_PATH, MockAuthorization::AuthorizeEndpoint
    suite_endpoint :post, EHR_AUTHORIZE_PATH, MockAuthorization::AuthorizeEndpoint
    suite_endpoint :post, EHR_TOKEN_PATH, MockAuthorization::TokenEndpoint

    # Payer
    suite_endpoint :post, QUESTIONNAIRE_PACKAGE_PATH, MockPayer::QuestionnairePackageEndpoint
    suite_endpoint :post, NEXT_PATH, MockPayer::NextQuestionEndpoint

    # EHR
    route(:get, METADATA_PATH, MockEHR.method(:metadata))
    suite_endpoint :post, QUESTIONNAIRE_RESPONSE_PATH, MockEHR::QuestionnaireResponseEndpoint
    suite_endpoint :get, FHIR_RESOURCE_PATH, MockEHR::FHIRGetEndpoint
    suite_endpoint :get, FHIR_SEARCH_PATH, MockEHR::FHIRGetEndpoint

    resume_test_route :get, RESUME_PASS_PATH do |request|
      request.query_parameters['client_id'] || request.query_parameters['token']
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      request.query_parameters['client_id'] || request.query_parameters['token']
    end

    # TODO: Update based on SMART Launch changes. Do we even want to have this group now?
    # group from: :oauth2_authentication

    group do
      id :dtr_smart_app_basic_workflows
      title 'Basic Workflows'
      description %(
        Tests in this group validate that the client can complete basic DTR workflows
      )

      group from: :dtr_smart_app_custom_static_workflow
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
      group from: :dtr_smart_app_static_dinner_questionnaire_workflow
    end
  end
end
