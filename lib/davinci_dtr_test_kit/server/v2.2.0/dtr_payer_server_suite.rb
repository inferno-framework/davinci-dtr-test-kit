require 'smart_app_launch_test_kit'
require_relative 'interaction_test'
require_relative 'log_questionnaire_errors_support_test'
require_relative 'next_question_support/invalid_questionnaire_response_test'
require_relative 'questionnaire_package_request_validation_test'
require_relative 'next_question_request_validation_test'
require_relative 'questionnaire_package_support/questionnaire_package_input_type_test'
require_relative 'questionnaire_package_support/questionnaire_response_validation_test'
require_relative 'questionnaire_design/cql_library_validation_test'
require_relative 'dtr_payer_server_capability_statement_test'
require_relative 'questionnaire_package_support/questionnaire_response_references_test'
require_relative 'questionnaire_package_support/contained_questionnaire_response_references_test'
require_relative 'next_question_support/next_question_response_references_test'
require_relative 'next_question_support/next_contained_questionnaire_response_references_test'
require_relative 'questionnaire_package_support/adaptive_questionnaire_response_validation_test'
require_relative 'value_set_expand_support/value_set_expansion_test'
require_relative 'questionnaire_design/questionnaire_expression_language_test'
require_relative 'questionnaire_design/questionnaire_prepopulation_test'
require_relative 'questionnaire_design/questionnaire_relevance_logic_test'
require_relative 'questionnaire_package_support/source_data_error_test'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRPayerServerSuiteV220 < Inferno::TestSuite
      id :dtr_payer_server_v220
      title 'Da Vinci DTR Payer Server Test Suite v2.2.0'
      description File.read(File.join(__dir__, 'dtr_payer_server_suite_description_v220.md'))

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
          url: 'https://hl7.org/fhir/us/davinci-dtr/2.2.0/'
        }
      ]

      requirement_sets(
        {
          identifier: 'hl7.fhir.us.davinci-dtr_2.2.0',
          title: 'Da Vinci Documentation Templates and Rules (DTR) v2.2.0',
          actor: 'DTR Server'
        }
      )

      fhir_resource_validator do
        igs('hl7.fhir.us.davinci-dtr#2.2.0')

        exclude_message do |message|
          message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
        end
      end

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'

      input :backend_services_smart_auth_info,
            title: 'OAuth Credentials',
            type: :auth_info,
            optional: true

      # All FHIR requests in this suite use this FHIR client.
      fhir_client do
        url :url
        auth_info :backend_services_smart_auth_info
      end

      group do
        title 'Discovery'

        # conf-1 - CS matches CS in the IG
        fhir_client do
          url :url
        end

        test from: :dtr_payer_server_v220_capability_statement_test
      end

      group from: :'smart_stu2-smart_backend_services' do
        # TODO
        # spec-120 [QUESTIONABLE]- payers require clients to use backend services
      end

      group do
        id :dtr_payer_server_v220_questionnaires
        title 'Questionnaire Operations'
        run_as_group

        input :backend_services_smart_auth_info,
              title: 'OAuth Credentials',
              type: :auth_info,
              optional: true
        input :client_fhir_endpoint,
              title: 'DTR Client FHIR Endpoint',
              description: 'Base URL of the DTR client FHIR endpoint. Required to validate absolute ' \
                           'QuestionnaireResponse references.',
              optional: true

        fhir_client do
          url :url
          auth_info :backend_services_smart_auth_info
        end

        group do
          title 'Questionnaire Interactions'

          group do
            title 'Interactions'
            # TODO: make #questionnaire_interaction identify static/adaptive questionnaires
            test from: :dtr_v220_payer_interaction
          end

          group do
            title 'Request Validation'
            simulation_verification

            test from: :dtr_v220_payer_questionnaire_package_request_validation
            test from: :dtr_v220_payer_next_question_request_validation
            test from: :dtr_v220_payer_questionnaire_package_input_type
          end
        end

        group do
          title 'Questionnaire/$questionnaire-package Support'
          # TODO: base response validation
          # oper-12 - [NOT TESTED in 2.0] include Questionnaire as 1st entry, [TESTED] and CQL libraries
          # oper-14 - [NOT TESTED in 2.0] Bundle includes all VS instances
          # oper-16 - [NOT TESTED in 2.0] references are version specific
          #           NOTE: ONLY Library references are currently tested
          test from: :dtr_v220_payer_questionnaire_response_validation

          # TODO: embedded QR validation
          # spec-25 - [NOT TESTED in 2.0] QR has contained Q
          # spec-122 - [NOT TESTED in 2.0] QR.Q points to canonical of the Q provided
          test from: :dtr_v220_payer_questionnaire_response_references
          test from: :dtr_v220_payer_contained_questionnaire_response_references
        end

        group do
          title 'Questionnaire/$next-question support'
          optional

          test from: :dtr_v220_payer_adaptive_questionnaire_response_validation
          test from: :dtr_v220_payer_next_question_response_references
          test from: :dtr_v220_payer_next_question_contained_response_references

          # spec-24 - [NOT TESTED in 2.0] url shall be a sub-url, accessed using same credentials

          # TODO
          # spec-39 - [QUESTIONABLE] display item indicating Q completion included at end
        end

        group do
          title 'Questionnaire design'

          # TODO
          # spec-96 - [NOT TESTED in 2.0] CQL and ELM are provided in expressions
          test from: :dtr_v220_payer_questionnaire_relevance_logic
          test from: :dtr_v220_payer_questionnaire_expression_language
          test from: :dtr_v220_payer_questionnaire_prepopulation

          # TODO
          # spec-93 - [NOT TESTED in 2.0] CQL has context of "Patient"
          # spec-94 - [NOT TESTED in 2.0] CQL follows SDC rules for determining context
          # spec-97 [QUESTIONABLE] - [NOT TESTED in 2.0] variables reference library if multiple libraries are used

          # TODO
          test from: :dtr_v220_payer_cql_library_validation

          # TODO
          # spec-160 - contained binary resources shall be pdfs or xhtml
          # spec-165 [QUESTIONABLE]- contained binary page reference validation

          # TODO
          # sec-4 - no hidden read-only questions
        end

        group do
          title 'ValueSet/$expand Support'
          test from: :dtr_v220_payer_value_set_expansion

          # TODO
          # oper-15 - [NOT TESTED in 2.0] VS with <40 entries SHALL be expanded
        end
      end

      group do
        title 'Log Questionnaire Error Support'
        # TODO
        # (optionally ?) perform $q-p operation and validate input

        test from: :dtr_v220_payer_log_questionnaire_errors_support
      end

      group do
        title 'Error Handling'

        input :backend_services_smart_auth_info,
              title: 'OAuth Credentials',
              type: :auth_info,
              optional: true

        fhir_client do
          url :url
          auth_info :backend_services_smart_auth_info
        end

        # TODO
        # oper-9 - make a request with a known bad questionnaire url

        test from: :dtr_v220_payer_source_data_error

        test from: :dtr_v220_payer_invalid_questionnaire_response
      end
    end
  end
end
