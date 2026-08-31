require 'smart_app_launch_test_kit'
require_relative 'interaction_test'
require_relative 'log_questionnaire_errors_support_test'
require_relative 'next_question_support/invalid_questionnaire_response_test'
require_relative 'questionnaire_package_request_validation_test'
require_relative 'next_question_request_validation_test'
require_relative 'questionnaire_package_support/questionnaire_package_input_type_test'
require_relative 'questionnaire_package_support/dtr_server_no_custom_extension_test'
require_relative 'questionnaire_package_support/questionnaire_response_validation_test'
require_relative 'questionnaire_package_support/dtr_server_questionnaire_package_contents_test'
require_relative 'questionnaire_package_support/initial_questionnaire_response_test'
require_relative 'next_question_support/next_question_response_validation_test'
require_relative 'questionnaire_package_support/dtr_server_questionnaire_not_found_test'
require_relative 'questionnaire_design/cql_library_validation_test'
require_relative 'dtr_payer_server_capability_statement_test'
require_relative 'questionnaire_package_support/questionnaire_response_references_test'
require_relative 'questionnaire_package_support/contained_questionnaire_response_references_test'
require_relative 'questionnaire_package_support/questionnaire_response_questionnaire_canonical_test'
require_relative 'questionnaire_package_support/questionnaire_references_version_specific_test'
require_relative 'next_question_support/next_question_response_references_test'
require_relative 'next_question_support/next_contained_questionnaire_response_references_test'
require_relative 'next_question_support/adaptive_questionnaire_endpoint_test'
require_relative 'questionnaire_package_support/adaptive_questionnaire_response_validation_test'
require_relative 'questionnaire_package_support/adaptive_questionnaire_response_contained_questionnaire_test'
require_relative 'value_set_expand_support/value_set_expansion_test'
require_relative 'questionnaire_design/questionnaire_expression_elm_test'
require_relative 'questionnaire_design/questionnaire_expression_language_test'
require_relative 'questionnaire_design/questionnaire_prepopulation_test'
require_relative 'questionnaire_design/questionnaire_relevance_logic_test'
require_relative 'questionnaire_package_support/source_data_error_test'
require_relative 'questionnaire_design/contained_binary_test'
require_relative 'questionnaire_package_support/value_set_validation_test'
require_relative 'must_support/questionnaire_package_output_parameters_must_support_test'
require_relative 'must_support/questionnaire_package_bundle_must_support_test'
require_relative 'must_support/questionnaire_base_must_support_test'
require_relative 'must_support/questionnaire_standard_must_support_test'
require_relative 'must_support/questionnaire_adaptive_must_support_test'
require_relative 'must_support/questionnaire_adaptive_search_must_support_test'

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

      fhir_client do
        url :url
        auth_info :backend_services_smart_auth_info
      end

      group do
        title 'Discovery'
        id :dtr_payer_v220_discovery
        description <<~DESCRIPTION
          The Discovery group verifies that a server advertises the required DTR
          functionality in its CapabilityStatement.
        DESCRIPTION

        run_as_group

        fhir_client do
          url :url
        end

        test from: :dtr_payer_server_v220_capability_statement_test
      end

      group from: :'smart_stu2-smart_backend_services' do
        id :dtr_payer_v220_backend_services
        description <<~DESCRIPTION
          The Backend Services group verifies that a server supports SMART
          backend services authorization and allows Inferno to obtain
          authorization to perform the DTR interactions in the rest of the
          suite.
        DESCRIPTION

        # TODO
        # spec-120 [QUESTIONABLE]- payers require clients to use backend services
      end

      group do
        id :dtr_payer_server_v220_questionnaire_operations
        title 'Questionnaire Operations'
        description <<~DESCRIPTION
          The Questionnaire Operations group submits user-provided requests to
          the server. Both the user-provided requests and the server's responses
          are validated to ensure they conform to the appropriate profiles.
        DESCRIPTION

        run_as_group

        input :backend_services_smart_auth_info,
              title: 'Backend Services Credentials',
              type: :auth_info
        input :client_fhir_endpoint,
              title: 'DTR Client FHIR Endpoint',
              description: 'Base URL of the DTR client FHIR endpoint. Required to validate absolute ' \
                           'QuestionnaireResponse references.',
              optional: true

        group do
          title 'Questionnaire Interactions'
          id :dtr_payer_v220_questionnaire_interactions
          description <<~DESCRIPTION
            The Questionnaire Interactions group makes `$questionnaire-package`,
            `$next-question`, and `ValueSet/$expand` requests to the server. The
            user-provided `$questionnaire-package` and `$next-question` request
            bodies are validated in this group, while the server responses are
            validated in later groups.

            `ValueSet/$expand` operations are automatically made for any
            returned ValueSets which need to be expanded.
          DESCRIPTION

          group do
            title 'Interactions'
            id :dtr_payer_v220_interactions
            description <<~DESCRIPTION
              This group makes all `$questionnaire-package`, `$next-question`,
              and `ValueSet/$expand` requests.
            DESCRIPTION

            test from: :dtr_v220_payer_interaction
          end

          group do
            title 'Request Validation'
            id :dtr_payer_v220_request_validation
            description <<~DESCRIPTION
              This group validates the user-provided `$questionnaire-package`
              and `$next-question` request bodies against the appropriate
              profiles, and verifies that all of the `$questionnaire-package`
              input types have been provided so that the server can demonstrate
              that it supports them all.
            DESCRIPTION

            simulation_verification

            test from: :dtr_v220_payer_questionnaire_package_request_validation
            test from: :dtr_v220_payer_next_question_request_validation
            test from: :dtr_v220_payer_questionnaire_package_input_type
          end
        end

        group do
          title 'Questionnaire/$questionnaire-package Support'
          id :dtr_payer_v220_questionnaire_package_support
          description <<~DESCRIPTION
            This group verifies that the server's responses to
            `$questionnaire-package` requests made in the "Questionnaire
            Interactions" group are valid.
          DESCRIPTION

          test from: :dtr_v220_payer_questionnaire_response_validation
          test from: :dtr_server_v220_payer_questionnaire_package_contents
          test from: :dtr_v220_payer_initial_questionnaire_response
          test from: :dtr_server_v220_no_custom_extension_test
          test from: :dtr_v220_payer_value_set_validation
          test from: :dtr_v220_payer_questionnaire_references_version_specific

          test from: :dtr_v220_payer_adaptive_questionnaire_response_contained_questionnaire
          test from: :dtr_v220_payer_questionnaire_response_questionnaire_canonical
          test from: :dtr_v220_payer_questionnaire_response_references
          test from: :dtr_v220_payer_contained_questionnaire_response_references
        end

        group do
          title 'Questionnaire/$next-question Support'
          id :dtr_payer_v220_next_question_support
          description <<~DESCRIPTION
            This group verifies that the server's responses to `$next-question`
            requests made in the "Questionnaire Interactions" group are valid
            and meet requirements specific to adaptive Questionnaires.
          DESCRIPTION

          test from: :dtr_v220_payer_next_question_response_validation
          test from: :dtr_v220_payer_adaptive_questionnaire_response_validation
          test from: :dtr_v220_payer_next_question_response_references
          test from: :dtr_v220_payer_next_question_contained_response_references
          test from: :dtr_v220_payer_adaptive_questionnaire_endpoint

          # TODO
          # spec-39 - [QUESTIONABLE] display item indicating Q completion included at end
        end

        group do
          title 'Questionnaire Design'
          id :dtr_payer_v220_questionnaire_design
          description <<~DESCRIPTION
            This group verifies that Questionnaires returned from
            `$questionnaire-package` and `$next-question` requests made in the
            "Questionnaire Interactions" meet common requirements from the DTR
            IG.
          DESCRIPTION

          test from: :dtr_v220_payer_questionnaire_relevance_logic
          test from: :dtr_v220_payer_questionnaire_expression_language
          test from: :dtr_v220_payer_questionnaire_expression_elm
          test from: :dtr_v220_payer_questionnaire_prepopulation

          # TODO
          # spec-93 - [NOT TESTED in 2.0] CQL has context of "Patient"
          # spec-94 - [NOT TESTED in 2.0] CQL follows SDC rules for determining context
          # spec-97 [QUESTIONABLE] - [NOT TESTED in 2.0] variables reference library if multiple libraries are used

          # TODO
          test from: :dtr_v220_payer_cql_library_validation

          test from: :dtr_v220_payer_contained_binary
          # spec-165 [QUESTIONABLE]- contained binary page reference validation

          # TODO
          # sec-4 - no hidden read-only questions
        end

        group do
          title 'ValueSet/$expand Support'
          id :dtr_payer_v220_valueset_expand_support
          description <<~DESCRIPTION
            This group verifies that the server's responses to
            `ValueSet/$expand` requests made in the "Questionnaire Interactions"
            group are valid.
          DESCRIPTION

          test from: :dtr_v220_payer_value_set_expansion

          # TODO
          # oper-15 - [NOT TESTED in 2.0] VS with <40 entries SHALL be expanded
        end

        group do
          id :dtr_payer_server_v220_must_support
          title 'Must Support'
          run_as_group

          test from: :dtr_v220_payer_questionnaire_package_output_parameters_must_support
          test from: :dtr_v220_payer_questionnaire_package_bundle_must_support
          test from: :dtr_v220_payer_questionnaire_base_must_support
          test from: :dtr_v220_payer_questionnaire_standard_must_support
          test from: :dtr_v220_payer_questionnaire_adaptive_must_support
          test from: :dtr_v220_payer_questionnaire_adaptive_search_must_support
        end

        group do
          title 'Error Handling'
          id :dtr_payer_v220_error_handling
          description <<~DESCRIPTION
            This group makes requests which contain errors and verifies that the
            server handles them in accordance with DTR IG requirements.
          DESCRIPTION

          test from: :dtr_server_v220_payer_questionnaire_not_found

          test from: :dtr_v220_payer_source_data_error

          test from: :dtr_v220_payer_invalid_questionnaire_response
        end
      end

      group do
        title 'Log Questionnaire Error Support'
        id :dtr_payer_v220_log_questionnaire_error_support
        description <<~DESCRIPTION
          This group performs a `$log-questionnaire-errors` operation and
          verifies the server's response.
        DESCRIPTION

        run_as_group

        input :backend_services_smart_auth_info,
              title: 'Backend Services Credentials',
              type: :auth_info

        test from: :dtr_v220_payer_log_questionnaire_errors_support
      end
    end
  end
end
