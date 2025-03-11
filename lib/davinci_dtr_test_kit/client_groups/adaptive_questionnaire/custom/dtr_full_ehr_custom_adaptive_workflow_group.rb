require_relative '../../../tags'
require_relative '../../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative 'dtr_full_ehr_custom_adaptive_request_test'
require_relative '../../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../dtr_adaptive_next_question_request_validation_test'
require_relative '../dtr_adaptive_response_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_libraries_test'
require_relative 'dtr_custom_next_question_response_validation_test'

# require_relative '../../full_ehr/dtr_full_ehr_adaptive_request_test'
# require_relative '../../shared/dtr_questionnaire_package_request_validation_test'
# require_relative '../dtr_adaptive_next_question_request_test'
# require_relative '../dtr_adaptive_next_question_request_validation_test'
# require_relative '../dtr_adaptive_response_validation_test'

# require_relative '../../shared/dtr_custom_questionnaire_package_validation_test'
# require_relative '../../shared/dtr_custom_questionnaire_libraries_test'
# require_relative '../../shared/dtr_custom_questionnaire_extensions_test'
# require_relative '../../shared/dtr_custom_questionnaire_expressions_test'
# require_relative 'dtr_custom_next_question_response_validation_test'
# require_relative '../../shared/dtr_prepopulation_attestation_test'
# require_relative '../../shared/dtr_prepopulation_override_attestation_test'

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

    # Test 0: attest to launch
    test from: :dtr_full_ehr_launch_attest,
         config: {
           options: {
             attestation_message: 'I attest that DTR has been launched in the context of a patient with data that will exercise pre-population logic in the provided static questionnaire resulting in at least 2 pre-populated answers.' # rubocop:disable Layout/LineLength
           }
         },
         title: 'Launch DTR (Attestation)'
    # Test 1: Recieve questionnaire-package and next-question requests
    test from: :dtr_custom_adative_request
    # Test 2: validate the $questionnaire-package request body
    test from: :dtr_qp_request_validation
    # Test 3: validate the $next-question requests body
    test from: :dtr_adaptive_next_question_request_validation
    # Test 4: validate the QuestionnaireResponse in the input parameter
    test from: :dtr_adaptive_response_validation do
      description %(
          Verify that the QuestionnaireResponse
            - Is conformant to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
            - Has source extensions demonstrating answers that are manually entered,
            automatically pre-populated, and manually overridden. (For `completed` QuestionnaireResponse)
            - Contains answers for all required items.
        )
    end
    # Test 5: validate the user provided $questionnaire-package response
    test from: :dtr_custom_qp_validation
    # Test 6: verify the custom response has the necessary libraries for pre-population
    test from: :dtr_custom_questionnaire_libraries
    # Test 7: validate the user provided $next-question questionnaires
    test from: :dtr_custom_next_questionnaire_validation

    # group do
    #   id :dtr_full_ehr_custom_adaptive_retrieval
    #   title 'Retrieving the Adaptive Questionnaire'
    #   description %()
    #   run_as_group

    #   input_order :access_token

    #   config(
    #     options: {
    #       attestation_message: %(
    #         I attest that DTR has been launched in the context of a patient with data that will
    #         exercise pre-population logic in the provided adaptive questionnaire resulting in at
    #         least 2 pre-populated answers.
    #       ),
    #       next_tag: "custom_initial_#{CLIENT_NEXT_TAG}"
    #     },
    #     inputs: {
    #       custom_next_question_questionnaire: {
    #         name: 'initial_custom_next_question_questionnaire',
    #         title: 'Custom Questionnaire resource to include in the initial $next-question Response'
    #       }
    #     }
    #   )

    #   # Test 0: attest to launch
    #   test from: :dtr_full_ehr_launch_attest,
    #        config: {
    #          options: {
    #            attestation_message: 'I attest that DTR has been launched in the context of a patient with data that will exercise pre-population logic in the provided static questionnaire resulting in at least 2 pre-populated answers.' # rubocop:disable Layout/LineLength
    #          }
    #        },
    #        title: 'Launch DTR (Attestation)'
    #   # Test 1: wait for the $questionnaire-package request and initial $next-question request
    #   test from: :dtr_full_ehr_adaptive_request do
    #     description %(
    #       This test waits for two sequential client requests:

    #       1. **Questionnaire Package Request**: The client should first invoke the `$questionnaire-package` operation
    #       to retrieve the adaptive questionnaire package. Inferno will respond to this request with the user
    #       provided empty adaptive questionnaire.

    #       2. **Initial Next Question Request**: After receiving the package, the client should invoke the
    #       `$next-question` operation. Inferno will respond by providing the user provided first set of questions.
    #     )
    #     input :custom_questionnaire_package_response, :custom_next_question_questionnaire
    #   end
    #   # Test 2: validate the $questionnaire-package request body
    #   test from: :dtr_qp_request_validation
    #   # Test 3: validate the $next-question request body
    #   test from: :dtr_adaptive_next_question_request_validation
    #   # Test 4: validate the QuestionnaireResponse in the input parameter
    #   test from: :dtr_adaptive_response_validation do
    #     description %(
    #       Verify that the QuestionnaireResponse
    #         - Is conformant to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
    #         - Has source extensions demonstrating answers that are manually entered,
    #         automatically pre-populated, and manually overridden. (For `completed` QuestionnaireResponse)
    #         - Contains answers for all required items.
    #     )
    #   end
    #   # Test 5: validate the user provided $questionnaire-package response
    #   test from: :dtr_custom_qp_validation
    #   # Test 6: verify the custom response has the necessary libraries for pre-population
    #   test from: :dtr_custom_questionnaire_libraries
    #   # Test 7: validate the user provided $next-question questionnaire
    #   test from: :dtr_custom_next_questionnaire_validation
    #   # Test 8: verify the custom response has the necessaru extensions for pre-population
    #   test from: :dtr_custom_questionnaire_extensions do
    #     title %(
    #       [USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response contain extensions
    #       necessary for pre-population
    #     )
    #     input :custom_next_question_questionnaire
    #   end
    #   # Test 9: verify custom response has necessary expressions for pre-population
    #   test from: :dtr_custom_questionnaire_expressions do
    #     title %(
    #       [USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response contain items with
    #       expressions necessary for pre-population
    #     )
    #     input :custom_next_question_questionnaire
    #   end
    # end

    # group do
    #   id :dtr_full_ehr_custom_adaptive_followup_questions
    #   title 'Retrieving the Next Question (Round 2)'
    #   description %()
    #   run_as_group
    #   config(
    #     options: {
    #       accepts_multiple_requests: true,
    #       next_tag: "custom_followup_#{CLIENT_NEXT_TAG}",
    #       next_question_prompt_title: 'Follow-up Next Question Request'
    #     },
    #     inputs: {
    #       custom_next_question_questionnaire: {
    #         name: 'followup_custom_next_question_questionnaire',
    #         title: 'Custom Questionnaire resource to include in the follow-up $next-question Response'
    #       }
    #     }
    #   )

    #   # Test 1: wait for the $next-question request
    #   test from: :dtr_adaptive_next_question_request do
    #     input :custom_next_question_questionnaire
    #   end
    #   # Test 2: validate the $next-question request
    #   test from: :dtr_adaptive_next_question_request_validation
    #   # Test 3: validate the QuestionnaireResponse in the input parameter
    #   test from: :dtr_adaptive_response_validation do
    #     description %(
    #         Verify that the QuestionnaireResponse
    #          - Is conformant to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
    #          - Has source extensions demonstrating answers that are manually entered,
    #           automatically pre-populated, and manually overridden. (For `completed` QuestionnaireResponse)
    #          - Contains answers for all required items.
    #       )
    #   end
    #   # Test 4: validate the user provided $next-question questionnaire
    #   test from: :dtr_custom_next_questionnaire_validation
    #   # Test 5: verify the custom response has the necessaru extensions for pre-population
    #   test from: :dtr_custom_questionnaire_extensions do
    #     title %(
    #       [USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response contain extensions
    #       necessary for pre-population
    #     )
    #     input :custom_questionnaire_package_response, :custom_next_question_questionnaire
    #   end
    #   # Test 6: verify custom response has necessary expressions for pre-population
    #   test from: :dtr_custom_questionnaire_expressions do
    #     title %(
    #       [USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response contain items with
    #       expressions necessary for pre-population
    #     )
    #     input :custom_next_question_questionnaire
    #   end
    # end

    # # This will be omitted if custom questionnaire not provided
    # group do
    #   id :dtr_full_ehr_custom_adaptive_followup_questions_2
    #   title 'Retrieving the Next Question (Round 3)'
    #   description %()
    #   run_as_group
    #   config(
    #     options: {
    #       accepts_multiple_requests: true,
    #       next_tag: "custom_followup2_#{CLIENT_NEXT_TAG}",
    #       next_question_prompt_title: 'Follow-up Next Question Request'
    #     },
    #     inputs: {
    #       custom_next_question_questionnaire: {
    #         name: 'followup2_custom_next_question_questionnaire',
    #         title: 'Custom Questionnaire resource to include in the Response of the third $next-question Request'
    #       }
    #     }
    #   )
    #   input :custom_questionnaire_package_response, optional: true, type: 'textarea'
    #   input :custom_next_question_questionnaire, optional: true

    #   # Test 1: wait for the $next-question request
    #   test from: :dtr_adaptive_next_question_request
    #   # Test 2: validate the $next-question request
    #   test from: :dtr_adaptive_next_question_request_validation
    #   # Test 3: validate the QuestionnaireResponse in the input parameter
    #   test from: :dtr_adaptive_response_validation do
    #     description %(
    #         Verify that the QuestionnaireResponse
    #          - Is conformant to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
    #          - Has source extensions demonstrating answers that are manually entered,
    #           automatically pre-populated, and manually overridden. (For `completed` QuestionnaireResponse)
    #          - Contains answers for all required items.
    #       )
    #   end
    #   # Test 4: validate the user provided $next-question questionnaire
    #   test from: :dtr_custom_next_questionnaire_validation
    #   # Test 5: verify the custom response has the necessaru extensions for pre-population
    #   test from: :dtr_custom_questionnaire_extensions do
    #     title %(
    #       [USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response contain extensions
    #       necessary for pre-population
    #     )
    #   end
    #   # Test 6: verify custom response has necessary expressions for pre-population
    #   test from: :dtr_custom_questionnaire_expressions do
    #     title %(
    #       [USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response contain items with
    #       expressions necessary for pre-population
    #     )
    #   end

    #   # Customize group result
    #   run do
    #     test1_result = results[tests.first.id].result
    #     omit_if test1_result == 'omit', 'Omitted: No next question or set of questions provided for this round.'
    #     skip_if(results.any? { |result| result.result == 'skip' })
    #     assert(results.all? { |result| result.result == 'pass' })
    #   end
    # end

    # group do
    #   id :dtr_full_ehr_custom_adaptive_completion
    #   title 'Completing the Adaptive Questionnaire'
    #   description %()
    #   run_as_group
    #   config(
    #     options: {
    #       accepts_multiple_requests: true,
    #       next_tag: "custom_completion_#{CLIENT_NEXT_TAG}",
    #       next_question_prompt_title: 'Last Next Question Request',
    #       custom_complete_questionnaire: true
    #     }
    #   )

    #   # Test 1: wait for the $next-question request
    #   test from: :dtr_adaptive_next_question_request
    #   # Test 2: validate the $next-question request
    #   test from: :dtr_adaptive_next_question_request_validation
    #   # Test 3: validate the QuestionnaireResponse in the input parameter
    #   test from: :dtr_adaptive_response_validation
    # end

    # group do
    #   title 'Attestation: Questionnaire Pre-Population and Rendering'
    #   description %(
    #     This group verifies that the tester has properly followed pre-population and rendering
    #     directives while interacting with and filling out the questionnaire.

    #     After retrieving and completing the questionnaire in their client system, the tester will
    #     attest that:
    #     1. The questionnaire was pre-populated as expected, with at least two answers pre-populated
    #       across all sets of questions.
    #     2. The questionnaire was rendered correctly according to its defined structure.
    #     3. They were able to manually enter responses, including overriding pre-populated answers.
    #   )
    #   test from: :dtr_prepopulation_attest
    #   test from: :dtr_prepopulation_override_attest
    # end
  end
end
