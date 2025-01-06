require_relative '../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../full_ehr/dtr_full_ehr_prepopulation_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_rendering_enabled_questions_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_prepopulation_override_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_saving_questionnaire_response_group'
require_relative 'dtr_custom_questionnaire_package_validation_test'
require_relative '../../payer_server_groups/static_form_libraries_test'
require_relative '../../payer_server_groups/static_form_questionnaire_extensions_test'
require_relative '../../payer_server_groups/static_form_questionnaire_expressions_test'

module DaVinciDTRTestKit
  class DTRFullEHRStaticDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_static_dinner_questionnaire_workflow
    title 'Static Questionnaire Workflow'
    description %(
      This test validates that a DTR Full EHR client can perform a full DTR Static Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate its ability to:

      1. Fetch the static questionnaire package
         ([DinnerOrderStatic](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_static/questionnaire_dinner_order_static.json))
      2. Render and pre-populate the questionnaire appropriately, including:
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled by other answers
      3. Complete and store the questionnaire response for future use.
    )

    group do
      id :dtr_full_ehr_static_questionnaire_retrieval
      title 'Retrieving the Static Questionnaire'
      description %(
        After DTR launch, Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and will return a static questionnaire for the
        tester to complete. Inferno will then validate the the conformance of the request.
      )
      run_as_group

      input_order :access_token, :custom_questionnaire_package_response

      def retrieval_method
        'Static'
      end

      # Test 0: attest to launch
      test from: :dtr_full_ehr_launch_attestation
      # Test 1: validate the user provided $questionnaire-package response
      test from: :dtr_custom_questionnaire_package_validation
      # Test 2: verify the custom response has the necessary libraries for pre-population
      test from: :dtr_v201_payer_static_form_libraries_test do
        title 'Custom Questionnaire Package response parameters contain libraries necessary for pre-population'
        description %(
          Inferno check that the custom response contains no duplicate library names
          and that libraries contain cql and elm data.
        )
      end

      # Test 3: verify the custom response has the necessaru extensions for pre-population
      test from: :dtr_v201_payer_static_form_extensions_test do
        title 'Custom static questionnaire(s) contain extensions necessary for pre-population'
        description %(
          Inferno checks that the custom response has appropriate extensions and references to libraries within
          those extensions.
        )
      end

      # Test 4: verify custom response has necessary expressions for pre-population
      test from: :dtr_v201_payer_static_form_expressions_test do
        title 'Custom static questionnaire(s) contain items with expressions necessary for pre-population'
        description %(
          Inferno checks that the custom response has appropriate expressions and that expressions are
          written in cql.
        )
      end
      # Test 5: wait for the $questionnaire-package request
      test from: :dtr_full_ehr_questionnaire_package_request
      # Test 6: validate the $questionnaire-package body
      test from: :dtr_questionnaire_package_request_validation
    end

    group do
      id :dtr_full_ehr_static_questionnaire_rendering
      title 'Filling Out the Static Questionnaire'
      description %(
        The tester will interact with the questionnaire within their client system
        such that pre-population steps are taken, the qustionnaire is rendered, and
        they are able to fill it out. The tester will attest that questionnaire pre-population
        and rendering directives were followed.
      )
      run_as_group

      # Test 1: attest to the pre-population of the name fields
      test from: :dtr_full_ehr_prepopulation_attestation
      # Test 2: attest to the pre-population and edit of the first name field
      test from: :dtr_full_ehr_prepopulation_override_attestation
      # Test 3: attest to the display of the toppings questions only when a dinner answer is selected
      test from: :dtr_full_ehr_rendering_enabled_questions_attestation
    end

    group from: :dtr_full_ehr_saving_questionnaire_response,
          config: {
            inputs: {
              questionnaire_response: {
                description: "The QuestionnaireResponse as exported from the EHR after completion of the Questionnaire.
                IMPORTANT: If you have not yet run the 'Filling Out the Static Questionnaire' group, leave this blank
                until you have done so. Then, run just the 'Saving the QuestionnaireResponse' group and populate
                this input."
              }
            }
          }
  end
end
