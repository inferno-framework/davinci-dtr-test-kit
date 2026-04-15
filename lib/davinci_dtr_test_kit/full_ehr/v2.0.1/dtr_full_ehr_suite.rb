require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative 'dtr_full_ehr_custom_static_workflow_group'
require_relative 'dtr_full_ehr_static_dinner_workflow_group'
require_relative 'dtr_full_ehr_adaptive_dinner_workflow_group'
require_relative 'dtr_full_ehr_custom_adaptive_workflow_group'
require_relative 'dtr_payer_registration_group'
require_relative 'dtr_full_ehr_questionnaire_must_support_group'
require_relative 'dtr_client_payer_auth_smart_group'
require_relative 'dtr_client_payer_auth_udap_group'
require_relative '../../cross_suite/cors'
require_relative '../endpoints/mock_udap_smart_server/token_endpoint'
require_relative '../endpoints/mock_payer/full_ehr_questionnaire_package_endpoint'
require_relative '../endpoints/mock_payer/full_ehr_next_question_endpoint'
require_relative '../dtr_full_ehr_options'

module DaVinciDTRTestKit
  class DTRFullEHRSuite < Inferno::TestSuite
    extend CORS

    id :dtr_full_ehr
    title 'Da Vinci DTR Full EHR Test Suite v2.0.1'
    description File.read(File.join(__dir__, 'dtr_full_ehr_suite_description_v201.md'))

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

    requirement_sets(
      {
        identifier: 'hl7.fhir.us.davinci-dtr_2.0.1',
        title: 'Da Vinci Documentation Templates and Rules (DTR) v2.0.1',
        actor: 'Full EHR'
      }
    )

    suite_option :client_type,
                 title: 'Client Security Type',
                 list_options: [
                   {
                     label: 'SMART Backend Services',
                     value: DTRFullEHROptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
                   },
                   {
                     label: 'UDAP B2B Client Credentials',
                     value: DTRFullEHROptions::UDAP_CLIENT_CREDENTIALS
                   }
                 ]

    # Hl7 Validator Wrapper:
    fhir_resource_validator do
      igs 'igs/davinci_dtr_2.0.1.tgz'

      exclude_message do |message|
        message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
      end
    end

    allow_cors QUESTIONNAIRE_PACKAGE_PATH, NEXT_PATH

    route(:get, UDAPSecurityTestKit::UDAP_DISCOVERY_PATH, lambda { |_env|
      UDAPSecurityTestKit::MockUDAPServer.udap_server_metadata(id)
    })
    route(:get, SMARTAppLaunch::SMART_DISCOVERY_PATH, lambda { |_env|
      SMARTAppLaunch::MockSMARTServer.smart_server_metadata(id)
    })

    suite_endpoint :post, UDAPSecurityTestKit::REGISTRATION_PATH,
                   UDAPSecurityTestKit::MockUDAPServer::RegistrationEndpoint
    suite_endpoint :post, UDAPSecurityTestKit::TOKEN_PATH, MockUdapSmartServer::TokenEndpoint

    suite_endpoint :post, QUESTIONNAIRE_PACKAGE_PATH, MockPayer::FullEHRQuestionnairePackageEndpoint
    suite_endpoint :post, NEXT_PATH, MockPayer::FullEHRNextQuestionEndpoint

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

    group from: :dtr_client_payer_auth_smart,
          required_suite_options: {
            client_type: DTRFullEHROptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
          }
    group from: :dtr_client_payer_auth_udap,
          required_suite_options: {
            client_type: DTRFullEHROptions::UDAP_CLIENT_CREDENTIALS
          }
  end
end
