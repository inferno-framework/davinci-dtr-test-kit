require_relative '../../../tags'
require_relative 'dtr_smart_app_custom_adaptive_request_test'
require_relative '../../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../dtr_adaptive_next_question_request_validation_test'
require_relative '../dtr_adaptive_response_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_libraries_test'
require_relative '../../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../../shared/dtr_custom_questionnaire_expressions_test'
require_relative 'dtr_custom_next_question_response_validation_test'
require_relative '../../shared/dtr_prepopulation_attestation_test'
require_relative '../../shared/dtr_prepopulation_override_attestation_test'
require_relative '../../smart_app/dtr_smart_app_saving_questionnaire_response_group'
require_relative '../../shared/dtr_questionnaire_response_prepopulation_test'

module DaVinciDTRTestKit
  class DTRSmartAppCustomAdaptiveWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_custom_adaptive_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This group validates that a DTR SMART App client can perform a full DTR Adaptive Questionnaire workflow.
      Testers will provide a custom adaptive Questionnaire package for the test, along with a list
      (JSON array) of Questionnaires to be included in each `$next-question` response.

      As part of this workflow, the SMART App system must demonstrate its ability to:

      1. Request the Questionnaire using the `$questionnaire-package` operation.
      2. Support the tester in completing the questionnaire through multiple `$next-question` interactions, including:
         - Rendering the questionnaire.
         - Pre-populating answers into the questionnaire.
         - Allowing the tester to manually enter responses, including overriding pre-populated answers.
      3. Provide the completed `QuestionnaireResponse` with appropriate indicators for pre-populated
         and manually-entered data.

      Inferno will process `$next-question` requests dynamically:
      - Each `$next-question` request will correspond to the next item in the provided list.
      - Inferno will sequentially return the corresponding Questionnaire from the list.
      - If a `$next-question` request is received when the list is empty, Inferno will mark
        the `QuestionnaireResponse` as completed.

      At least two answers should be pre-populated across all sets of questions.
    )
    run_as_group

    config(
      options: {
        smart_app: true,
        form_type: 'adaptive',
        next_tag: "custom_#{CLIENT_NEXT_TAG}"
      },
      inputs: {
        custom_questionnaire_package_response: {
          name: 'adaptive_custom_questionnaire_package_response',
          title: 'Custom Questionnaire Package Response JSON for Adaptive form',
          description: %(
              A JSON PackageBundle may be provided here to replace Inferno's response to
              the $questionnaire-package request. Note: Ensure that the questionnaire package
              has an empty Adaptive Questionnaire.
            )
        }
      }
    )

    group do
      id :dtr_smart_app_custom_adaptive_retrieval
      title 'Retrieving the Adaptive Questionnaire'

      # Test 1: wait for the $questionnaire-package request and initial $next-question request
      test from: :dtr_smart_app_custom_adative_request
      # Test 2: validate the $questionnaire-package request body
      test from: :dtr_qp_request_validation
      # Test 3: validate the $next-question request body
      test from: :dtr_adaptive_next_question_request_validation
      # Test 4: validate the QuestionnaireResponse in the input parameter
      test from: :dtr_adaptive_response_validation do
        description %(
          Verify that all submitted QuestionnaireResponse resources meet the following criteria:
          - Conform to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
          - Include source extensions indicating whether answers were manually entered,
            automatically pre-populated, or manually overridden (for `completed` QuestionnaireResponse).
          - Provide answers for all required items in their contained Questionnaire.
        )
        input :custom_next_question_questionnaires
      end
      # Test 5: validate the user provided $questionnaire-package response
      test from: :dtr_custom_qp_validation
      # Test 6: verify the custom response has the necessary libraries for pre-population
      test from: :dtr_custom_questionnaire_libraries
      # Test 7: validate the user provided $next-question questionnaire
      test from: :dtr_custom_next_questionnaire_validation
      # Test 8: verify the custom response has the necessaru extensions for pre-population
      test from: :dtr_custom_questionnaire_extensions do
        title %(
          [USER INPUT VERIFICATION] Custom Questionnaires for $next-question Responses contain extensions
          necessary for pre-population
        )
        input :custom_next_question_questionnaires
      end
      # Test 9: verify custom response has necessary expressions for pre-population
      test from: :dtr_custom_questionnaire_expressions do
        title %(
          [USER INPUT VERIFICATION] Custom Questionnaires for $next-question Responses contain items with
          expressions necessary for pre-population
        )
        input :custom_next_question_questionnaires
      end
    end

    group do
      title 'Attestation: Questionnaire Pre-Population and Rendering'
      description %(
        This group verifies that the tester has properly followed pre-population and rendering
        directives while interacting with and filling out the questionnaire.

        After retrieving and completing the questionnaire in their client system, the tester will
        attest that:
        1. The questionnaire was pre-populated as expected, with at least two answers pre-populated
          across all sets of questions.
        2. The questionnaire was rendered correctly according to its defined structure.
        3. They were able to manually enter responses, including overriding pre-populated answers.
      )
      test from: :dtr_prepopulation_attest
      test from: :dtr_prepopulation_override_attest
    end

    group from: :dtr_smart_app_saving_qr do
      config(
        options: {
          custom: true,
          adaptive: true,
          qr_profile_url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt'
        }
      )

      test from: :dtr_qr_prepopulation,
           uses_request: :questionnaire_response_save,
           description: %(
            The tester will complete the questionnaire such that a QuestionnaireResponse is
            stored back into Inferno's EHR endpoint. The stored QuestionnaireResponse will be evaluated for:
            - Has source extensions demonstrating answers that are manually entered,
              automatically pre-populated, and manually overridden.
            - Contains answers for all required items.
           )
    end
  end
end
