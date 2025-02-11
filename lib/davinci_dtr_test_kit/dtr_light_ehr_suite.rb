require 'us_core_test_kit'
require 'tls_test_kit'
require_relative 'version'
require_relative 'dtr_options'
require_relative 'profiles/questionnaire_response_group'
require_relative 'profiles/coverage_group'
require_relative 'profiles/communication_request_group'
require_relative 'profiles/device_request_group'
require_relative 'profiles/encounter_group'
require_relative 'profiles/medication_request_group'
require_relative 'profiles/nutrition_order_group'
require_relative 'profiles/service_request_group'
require_relative 'profiles/task_group'
require_relative 'profiles/vision_prescription_group'
require_relative 'client_groups/light_ehr/dtr_smart_standalone_launch'
require_relative 'client_groups/light_ehr/dtr_smart_ehr_launch'
require 'smart_app_launch/smart_stu1_suite'
require 'smart_app_launch/smart_stu2_suite'

module DaVinciDTRTestKit
  class DTRLightEHRSuite < Inferno::TestSuite
    id :dtr_light_ehr
    title 'Da Vinci DTR Light EHR Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_light_ehr_suite_description_v201.md'))

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

    input :url,
          title: 'FHIR Server Base Url',
          description: 'URL of the target DTR Light EHR'

    # Hl7 Validator Wrapper:
    fhir_resource_validator do
      igs('hl7.fhir.us.davinci-dtr#2.0.1', 'hl7.fhir.us.davinci-pas#2.0.1', 'hl7.fhir.us.davinci-crd#2.0.1')

      exclude_message do |message|
        message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
      end
    end

    group do
      title 'Authorization'

      group from: :smart_discovery_stu2 do
        required_suite_options DTROptions::SMART_2_REQUIREMENT
        run_as_group

        test from: :tls_version_test do
          title 'DTR FHIR Server is secured by transport layer security'
          description <<~DESCRIPTION
            Under [Privacy, Security, and Safety](https://hl7.org/fhir/us/davinci-crd/STU2/security.html),
            the DTR Implementation Guide imposes the following rule about TLS:
            As per the [DTR Hook specification](https://cds-hooks.hl7.org/2.0/#security-and-safety),
            communications between DTR Clients and DTR Servers SHALL
            use TLS. Mutual TLS is not required by this specification but is permitted. DTR Servers and
            DTR Clients SHOULD enforce a minimum version and other TLS configuration requirements based
            on HRex rules for PHI exchange.
            This test verifies that the FHIR server is using TLS 1.2 or higher.
          DESCRIPTION

          id :dtr_server_tls_version_stu2

          config(
            options: { minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
          )
        end
      end

      group from: :dtr_smart_standalone_launch,
            required_suite_options: DTROptions::SMART_2_REQUIREMENT,
            run_as_group: true,
            config: {
              outputs: {
                id_token: { name: :id_token },
                token_retrieval_time: { name: :token_retrieval_time },
                refresh_token: { name: :refresh_token },
                received_scopes: { name: :received_scopes },
                access_token: { name: :access_token },
                smart_credentials: { name: :smart_credentials }
              }
            }

      group from: :dtr_smart_ehr_launch,
            required_suite_options: DTROptions::SMART_2_REQUIREMENT,
            run_as_group: true,
            config: {
              outputs: {
                id_token: { name: :id_token },
                client_id: { name: :client_id },
                requested_scopes: { name: :requested_scopes },
                access_token: { name: :access_token },
                smart_credentials: { name: :smart_credentials }
              }
            }
    end

    group do
      title 'FHIR API'
      description %(This test group tests systems for their conformance to
      the US Core v3.1.1 Capability Statement as defined by the DaVinci Documentation
      Templates and Rules (DTR) v2.0.1 Implementation Guide Light DTR EHR
      Capability Statement.

      )

      group from: :'us_core_v311-us_core_v311_fhir_api',
            run_as_group: true,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                smart_credentials: { name: :ehr_smart_credentials }
              }
            }
    end

    group do
      title 'DTR Light EHR Profiles'
      description %(This test group tests system for their conformance to
      the RESTful capabilities by specified Resources/Profiles as defined by
      the DaVinci Documentation Templates and Rules (DTR) v2.0,1 Implementation
      Guide Light DTR EHR Capability Statement.

      )

      input :smart_credentials,
            title: 'OAuth Credentials',
            type: :oauth_credentials,
            optional: true

      # All FHIR requests in this suite will use this FHIR client
      fhir_client do
        url :url
        oauth_credentials :smart_credentials
      end

      group from: :questionnaire_response_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :coverage_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :communication_request_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :device_request_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :encounter_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :medication_request_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :nutrition_order_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :service_request_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :task_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
      group from: :vision_prescription_group,
            config: {
              inputs: {
                id_token: { name: :ehr_id_token },
                client_id: { name: :ehr_client_id },
                requested_scopes: { name: :ehr_requested_scopes },
                access_token: { name: :ehr_access_token },
                credentials: { name: :ehr_smart_credentials }
              }
            }
    end
  end
end
