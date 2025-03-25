require_relative 'client_groups/custom_static/dtr_full_ehr_custom_static_workflow_group'
require_relative 'client_groups/dinner_static/dtr_full_ehr_static_dinner_workflow_group'
require_relative 'client_groups/adaptive_questionnaire/dinner_order/dtr_full_ehr_adaptive_dinner_workflow_group'
require_relative 'client_groups/adaptive_questionnaire/custom/dtr_full_ehr_custom_adaptive_workflow_group'
require_relative 'client_groups/payer_registration/dtr_client_registration_group'
require_relative 'client_groups/must_support/dtr_full_ehr_questionnaire_must_support_group'
require_relative 'client_groups/auth/dtr_client_payer_auth_group'
require_relative 'endpoints/cors'
require_relative 'endpoints/mock_udap_smart_server'
require_relative 'endpoints/mock_udap_smart_server/registration'
require_relative 'endpoints/mock_udap_smart_server/token'
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
      igs 'igs/davinci_dtr_2.0.1.tgz'

      exclude_message do |message|
        message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
      end
    end

    allow_cors QUESTIONNAIRE_PACKAGE_PATH, NEXT_PATH, SESSION_QUESTIONNAIRE_PACKAGE_PATH, SESSION_NEXT_PATH

    route(:get, UDAP_DISCOVERY_PATH, MockUdapSmartServer.method(:udap_server_metadata))
    route(:get, SMART_DISCOVERY_PATH, MockUdapSmartServer.method(:smart_server_metadata))

    suite_endpoint :post, REGISTRATION_PATH, MockUdapSmartServer::RegistrationEndpoint
    suite_endpoint :post, TOKEN_PATH, MockUdapSmartServer::TokenEndpoint

    suite_endpoint :post, QUESTIONNAIRE_PACKAGE_PATH, MockPayer::FullEHRQuestionnairePackageEndpoint
    suite_endpoint :post, SESSION_QUESTIONNAIRE_PACKAGE_PATH, MockPayer::FullEHRQuestionnairePackageEndpoint
    suite_endpoint :post, NEXT_PATH, MockPayer::FullEHRNextQuestionEndpoint
    suite_endpoint :post, SESSION_NEXT_PATH, MockPayer::FullEHRNextQuestionEndpoint

    resume_test_route :get, RESUME_PASS_PATH do |request|
      request.query_parameters['token']
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      request.query_parameters['token']
    end

    group from: :dtr_client_payer_registration
    group do
      id :dtr_full_ehr_basic_workflows
      title 'Basic Workflows'

      group from: :dtr_full_ehr_custom_static_workflow
      group from: :dtr_full_ehr_custom_adaptive_workflow
    end
    group do
      id :dtr_full_ehr_questionnaire_functionality
      title 'Questionnaire Functionality Coverage'
      description %(
        Tests in this group validate that the client can complete additional DTR workflows
        covering additional pre-population features of questionnaires.
      )
      group from: :dtr_full_ehr_static_dinner_workflow
      group from: :dtr_full_ehr_adaptive_dinner_workflow
    end
    group from: :dtr_full_ehr_questionnaire_ms
    group from: :dtr_client_payer_auth
  end
end
