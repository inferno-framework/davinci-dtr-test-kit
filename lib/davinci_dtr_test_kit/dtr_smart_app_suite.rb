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
    extend MockPayer
    extend MockEHR

    id :dtr_smart_app
    title 'Da Vinci DTR SMART App Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_smart_app_suite_description_v201.md'))

    version VERSION

    # All FHIR validation requsets will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    allow_cors QUESTIONNAIRE_PACKAGE_PATH, QUESTIONNAIRE_RESPONSE_PATH, FHIR_RESOURCE_PATH, FHIR_SEARCH_PATH

    route(:get, '/fhir/metadata', method(:metadata_handler))

    record_response_route :post, TOKEN_PATH, 'dtr_auth', method(:token_response) do |request|
      DTRSmartAppSuite.extract_client_id(request)
    end

    record_response_route :post, QUESTIONNAIRE_PACKAGE_PATH, QUESTIONNAIRE_PACKAGE_TAG,
                          method(:questionnaire_package_response), resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_bearer_token(request)
    end

    record_response_route :post, QUESTIONNAIRE_RESPONSE_PATH, 'dtr_smart_app_questionnaire_response',
                          method(:questionnaire_response_response) do |request|
      DTRSmartAppSuite.extract_bearer_token(request)
    end

    record_response_route :get, FHIR_RESOURCE_PATH, SMART_APP_EHR_REQUEST_TAG, method(:get_fhir_resource),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_bearer_token(request)
    end

    record_response_route :get, FHIR_SEARCH_PATH, SMART_APP_EHR_REQUEST_TAG, method(:get_fhir_resource),
                          resumes: ->(_) { false } do |request|
      DTRSmartAppSuite.extract_bearer_token(request)
    end

    resume_test_route :get, RESUME_PASS_PATH do |request|
      DTRSmartAppSuite.extract_token_from_query_params(request)
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      DTRSmartAppSuite.extract_token_from_query_params(request)
    end

    group from: :oauth2_authentication
    group do
      id :dtr_smart_app_basic_workflows
      title 'Basic Workflows'
      description %(
        Tests in this group validate that the client can complete basic DTR workflows
      )

      group from: :dtr_smart_app_static_dinner_questionnaire_workflow
      # group from: :dtr_smart_app_adaptive_dinner_questionnaire_workflow - TODO
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
