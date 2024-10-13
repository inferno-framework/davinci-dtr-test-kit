require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'client_groups/dinner_static/dtr_full_ehr_questionnaire_workflow_group'
require_relative 'client_groups/dinner_adaptive/dtr_full_ehr_adaptive_dinner_questionnaire_workflow_group'
require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'mock_payer'
require_relative 'version'

module DaVinciDTRTestKit
  class DTRFullEHRSuite < Inferno::TestSuite
    extend MockPayer
    extend MockAuthServer

    id :dtr_full_ehr
    title 'Da Vinci DTR Full EHR Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_full_ehr_suite_description_v201.md'))

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

    allow_cors QUESTIONNAIRE_PACKAGE_PATH, NEXT_PATH

    record_response_route :post, PAYER_TOKEN_PATH, 'dtr_full_ehr_payer_token',
                          method(:payer_token_response) do |request|
      DTRFullEHRSuite.extract_client_id_from_form_params(request)
    end

    record_response_route :post, QUESTIONNAIRE_PACKAGE_PATH, QUESTIONNAIRE_PACKAGE_TAG,
                          method(:questionnaire_package_response) do |request|
      DTRFullEHRSuite.extract_bearer_token(request)
    end

    record_response_route :post, NEXT_PATH, NEXT_TAG,
                          method(:client_questionnaire_next_response) do |request|
      DTRFullEHRSuite.extract_bearer_token(request)
    end

    resume_test_route :get, RESUME_PASS_PATH do |request|
      DTRFullEHRSuite.extract_token_from_query_params(request)
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      DTRFullEHRSuite.extract_token_from_query_params(request)
    end

    group from: :oauth2_authentication
    group from: :dtr_full_ehr_static_dinner_questionnaire_workflow
    group from: :dtr_full_ehr_adaptive_dinner_questionnaire_workflow
  end
end
