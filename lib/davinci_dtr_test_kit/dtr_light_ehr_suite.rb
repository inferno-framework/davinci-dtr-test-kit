require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require 'us_core_test_kit'
require 'tls_test_kit'
require_relative 'version'
require_relative 'dtr_options'
require_relative 'profiles/questionnaire_response/questionnaire_response_patient_search'
require_relative 'profiles/questionnaire_response/questionnaire_response_context_search'
require_relative 'profiles/questionnaire_response/questionnaire_response_read'
require_relative 'profiles/questionnaire_response/questionnaire_response_validation'
require_relative 'profiles/questionnaire_response/questionnaire_response_create'
require_relative 'profiles/questionnaire_response/questionnaire_response_update'
require_relative 'profiles/coverage/coverage_read'
require_relative 'profiles/coverage/coverage_validation'
require_relative 'profiles/communication_request/communication_request_read'
require_relative 'profiles/communication_request/communication_request_validation'
require_relative 'profiles/device_request/device_request_read'
require_relative 'profiles/device_request/device_request_validation'
require_relative 'profiles/encounter/encounter_read'
require_relative 'profiles/encounter/encounter_validation'
require_relative 'profiles/medication_request/medication_request_read'
require_relative 'profiles/medication_request/medication_request_validation'
require_relative 'profiles/nutrition_order/nutrition_order_read'
require_relative 'profiles/nutrition_order/nutrition_order_validation'
require_relative 'profiles/service_request/service_request_read'
require_relative 'profiles/service_request/service_request_validation'
require_relative 'profiles/task/task_read'
require_relative 'profiles/task/task_validation'
require_relative 'profiles/task/task_create'
require_relative 'profiles/task/task_update'
require_relative 'profiles/vision_prescription/vision_prescription_read'
require_relative 'profiles/vision_prescription/vision_prescription_validation'
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
          title: 'FHIR Endpoint',
          description: 'URL of the DTR FHIR server'

    # Hl7 Validator Wrapper:
    fhir_resource_validator do
      igs('hl7.fhir.us.davinci-dtr#2.0.1', 'hl7.fhir.us.davinci-cdex#2.0.0', 'hl7.fhir.us.davinci-crd#2.0.1')

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

      group from: :smart_ehr_launch_stu2,
            required_suite_options: DTROptions::SMART_2_REQUIREMENT,
            run_as_group: true

      group from: :smart_standalone_launch_stu2,
            required_suite_options: DTROptions::SMART_2_REQUIREMENT,
            run_as_group: true
    end

    group do
      title 'FHIR API'

      group from: :'us_core_v311-us_core_v311_fhir_api',
            run_as_group: true
    end

    group do
      title 'DTR Light EHR Profiles'

      input :credentials,
            title: 'OAuth Credentials',
            type: :oauth_credentials,
            optional: true

      # All FHIR requests in this suite will use this FHIR client
      fhir_client do
        url :url
        oauth_credentials :credentials
      end

      group do
        title 'DTR QuestionnaireResponse'
        run_as_group

        test from: :questionnaire_response_patient_search
        test from: :questionnaire_response_context_search
        test from: :questionnaire_response_read
        test from: :questionnaire_response_validation
        test from: :questionnaire_response_create
        test from: :questionnaire_response_update
      end

      group do
        title 'CRD Coverage'
        run_as_group

        input :coverage_ids

        test from: :coverage_read
        test from: :coverage_validation
      end

      group do
        title 'CRD CommunicationRequest'
        run_as_group

        input :communication_request_ids

        test from: :communication_request_read
        test from: :communication_request_validation
      end

      group do
        title 'CRD DeviceRequest'
        run_as_group

        input :device_request_ids

        test from: :device_request_read
        test from: :device_request_validation
      end

      group do
        title 'CRD Encounter'
        run_as_group

        input :encounter_ids

        test from: :encounter_read
        test from: :encounter_validation
      end

      group do
        title 'CRD MedicationRequest'
        run_as_group

        input :medication_request_ids

        test from: :medication_request_read
        test from: :medication_request_validation
      end

      group do
        title 'CRD NutritionOrder'
        run_as_group

        input :nutrition_order_ids

        test from: :nutrition_order_read
        test from: :nutrition_order_validation
      end

      group do
        title 'CRD ServiceRequest'
        run_as_group

        input :service_request_ids

        test from: :service_request_read
        test from: :service_request_validation
      end

      group do
        title 'CDex Task'
        run_as_group

        input :task_ids

        test from: :task_read
        test from: :task_validation
        test from: :task_create
        test from: :task_update
      end

      group do
        title 'CRD VisionPrescription'
        run_as_group

        input :vision_prescription_ids

        test from: :vision_prescription_read
        test from: :vision_prescription_validation
      end
    end
  end
end
