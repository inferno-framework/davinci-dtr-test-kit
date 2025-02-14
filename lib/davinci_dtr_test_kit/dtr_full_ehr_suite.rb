require_relative 'client_groups/custom_static_questionnaire/dtr_full_ehr_custom_questionnaire_workflow_group'
require_relative 'client_groups/dinner_static/dtr_full_ehr_questionnaire_workflow_group'
require_relative 'client_groups/dinner_adaptive/dtr_full_ehr_adaptive_dinner_questionnaire_workflow_group'
require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'endpoints/cors'
require_relative 'endpoints/mock_authorization/simple_token_endpoint'
require_relative 'endpoints/mock_payer/full_ehr_questionnaire_package_endpoint'
require_relative 'endpoints/mock_payer/full_ehr_next_question_endpoint'
require_relative 'version'

module DaVinciDTRTestKit
  class DTRFullEHRSuite < Inferno::TestSuite
    extend CORS

    id :dtr_full_ehr
    title 'Da Vinci DTR Full EHR Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_full_ehr_suite_description_v201.md'))

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

    suite_endpoint :post, PAYER_TOKEN_PATH, MockAuthorization::SimpleTokenEndpoint

    suite_endpoint :post, QUESTIONNAIRE_PACKAGE_PATH, MockPayer::FullEHRQuestionnairePackageEndpoint
    suite_endpoint :post, NEXT_PATH, MockPayer::FullEHRNextQuestionEndpoint

    resume_test_route :get, RESUME_PASS_PATH do |request|
      request.query_parameters['token']
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      request.query_parameters['token']
    end

    group from: :oauth2_authentication
    group do
      id :dtr_full_ehr_basic_workflows
      title 'Basic Workflows'

      group from: :dtr_full_ehr_custom_static_questionnaire_workflow
      group from: :dtr_full_ehr_adaptive_dinner_questionnaire_workflow
    end
    group do
      id :dtr_full_ehr_questionnaire_functionality
      title 'Questionnaire Functionality Coverage'
      description %(
        Tests in this group validate that the client can complete additional DTR workflows
        covering additional pre-population features of questionnaires.
      )
      group from: :dtr_full_ehr_static_dinner_questionnaire_workflow
    end
  end
end
