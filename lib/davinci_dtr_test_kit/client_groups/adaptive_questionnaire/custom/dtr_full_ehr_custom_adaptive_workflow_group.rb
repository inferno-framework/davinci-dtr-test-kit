require_relative '../../../tags'
require_relative '../../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative 'dtr_full_ehr_custom_adaptive_request_test'
require_relative '../../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../dtr_adaptive_next_question_request_validation_test'
require_relative '../dtr_adaptive_response_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_libraries_test'
require_relative 'dtr_custom_next_question_response_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../../shared/dtr_custom_questionnaire_expressions_test'
require_relative '../../shared/dtr_prepopulation_attestation_test'
require_relative '../../shared/dtr_prepopulation_override_attestation_test'
require_relative '../../full_ehr/dtr_full_ehr_store_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRCustomAdaptiveWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_custom_adaptive_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This group validates that a DTR Full EHR client can perform a full DTR Adaptive Questionnaire workflow.
      Testers will provide a custom adaptive Questionnaire package for the test, along with a list
      (JSON array) of Questionnaires to be included in each `$next-question` response.

      As part of this workflow, the Full EHR system must demonstrate its ability to:

      1. Request the Questionnaire using the `$questionnaire-package` operation.
      2. Support the tester in completing the questionnaire through multiple `$next-question` interactions, including:
         - Rendering the questionnaire.
         - Pre-populating answers into the questionnaire.
         - Allowing the tester to manually enter responses, including overriding pre-populated answers.
      3. Complete and store the `QuestionnaireResponse` for future use.

      Inferno will process `$next-question` requests dynamically:
      - Each request will receive the next Questionnaire from the provided list.
      - If a `$next-question` request is received when the list is empty, Inferno will mark
        the `QuestionnaireResponse` as completed.

      At least two answers should be pre-populated across all sets of questions.
    )
    run_as_group
    config(
      options: { form_type: 'adaptive', next_tag: "custom_#{CLIENT_NEXT_TAG}" },
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

    input_order :access_token

    group do
      id :dtr_full_ehr_custom_adaptive_retrieval
      title 'Retrieving the Adaptive Questionnaire'

      # Test 0: attest to launch
      test from: :dtr_full_ehr_launch_attest,
           config: {
             options: {
               attestation_message: 'I attest that DTR has been launched in the context of a patient with data that will exercise pre-population logic in the provided static questionnaire resulting in at least 2 pre-populated answers.' # rubocop:disable Layout/LineLength
             }
           },
           title: 'Launch DTR (Attestation)'
      # Test 1: Recieve questionnaire-package and next-question requests
      test from: :dtr_full_ehr_custom_adative_request
      # Test 2: validate the $questionnaire-package request body
      test from: :dtr_qp_request_validation
      # Test 3: validate the $next-question requests body
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
      # Test 7: validate the user provided $next-question questionnaires
      test from: :dtr_custom_next_questionnaire_validation
      # Test 8: verify the custom responses has the necessaru extensions for pre-population
      test from: :dtr_custom_questionnaire_extensions do
        title %(
          [USER INPUT VERIFICATION] Custom Questionnaires for $next-question Responses contain extensions
          necessary for pre-population
        )
        input :custom_next_question_questionnaires
      end
      # Test 9: verify custom responses has necessary expressions for pre-population
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

    group do
      title 'Attestation: QuestionnaireResponse Completion and Storage'
      description %(
        The tester will attest to the completion of the questionnaire such that the results are stored for later use.
      )

      test from: :dtr_full_ehr_store_attest
    end
  end
end
