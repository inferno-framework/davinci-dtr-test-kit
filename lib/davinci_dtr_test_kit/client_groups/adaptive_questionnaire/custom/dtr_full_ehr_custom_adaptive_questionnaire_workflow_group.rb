require_relative '../../../tags'
require_relative '../../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative '../../full_ehr/dtr_full_ehr_adaptive_questionnaire_request_test'
require_relative '../../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../dtr_adaptive_questionnaire_next_question_request_test'
require_relative '../dtr_adaptive_questionnaire_next_question_request_validation_test'
require_relative '../dtr_adaptive_questionnaire_response_validation_test'

require_relative '../../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_libraries_test'
require_relative '../../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../../shared/dtr_custom_questionnaire_expressions_test'
require_relative 'dtr_custom_next_question_response_validation_test'
require_relative '../../shared/dtr_prepopulation_attestation_test'
require_relative '../../shared/dtr_prepopulation_override_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRCustomAdaptiveQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_custom_adaptive_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This group validates that a DTR Full EHR client can perform a full DTR Adaptive Questionnaire workflow.
      Testers will provide a custom adaptive Questionnaire package for the test, along with 2-3 responses to
      2-3 `$next-question` requests. As a part of this workflow, the Full EHR system must demonstrate its ability to:

      1. Request the Questionnaire using the $questionnaire-package operation.
      2. Request the first set of questions using the $next-question operation.
      3. Support the tester in completing the first set of questions, including:
         - Rendering the questionnaire.
         - Pre-populating answers into the questionnaire.
         - Allowing the tester to manually enter responses, including overriding pre-populated answers.
      4. Request the next set of questions using the $next-question operation and support the tester in completing
         the second set of questions.
      5. Repeat step 4 if three responses to the `$next-question` request were provided.
      6. Complete and store the QuestionnaireResponse for future use.

      At least two answers should be pre-populated across all sets of questions.
    )

    group do
      id :dtr_full_ehr_custom_adaptive_retrieval
      title 'Retrieving the Adaptive Questionnaire'
      description %()
      run_as_group

      # input :custom_questionnaire_package_response, :custom_next_question_questionnaire
      input_order :access_token

      config(
        options: {
          attestation_message: %(
            I attest that DTR has been launched in the context of a patient with data that will
            exercise pre-population logic in the provided adaptive questionnaire resulting in at
            least 2 pre-populated answers.
          ),
          form_type: 'adaptive'
        },
        inputs: {
          custom_questionnaire_package_response: {
            name: 'custom_adaptive_questionnaire_package_response'
          },
          custom_next_question_questionnaire: {
            name: 'custom_initial_next_question_questionnaire',
            title: 'Custom Questionnaire resource to include in the initial $next-question Response'
          }
        }
      )

      group do
        title 'Adaptive Questionnaire Package and Initial Questions Retrieval'
        config(options: { next_tag: "custom_initial_#{CLIENT_NEXT_TAG}" })
        run_as_group

        # Test 0: attest to launch
        test from: :dtr_full_ehr_launch_attestation,
             config: {
               options: {
                 attestation_message: 'I attest that DTR has been launched in the context of a patient with data that will exercise pre-population logic in the provided static questionnaire resulting in at least 2 pre-populated answers.' # rubocop:disable Layout/LineLength
               }
             },
             title: 'Launch DTR (Attestation)'
        # Test 1: wait for the $questionnaire-package request and initial $next-question request
        test from: :dtr_full_ehr_adaptive_questionnaire_request do
          input :custom_questionnaire_package_response, :custom_next_question_questionnaire
        end
        # Test 2: validate the $questionnaire-package request body
        test from: :dtr_questionnaire_package_request_validation
        # Test 3: validate the $next-question request body
        test from: :dtr_next_question_request_validation
        # Test 4: validate the QuestionnaireResponse in the input parameter
        test from: :dtr_adaptive_questionnaire_response_validation do
          description %(
            Verify that the QuestionnaireResponse
             - Is conformant to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
             - Has source extensions demonstrating answers that are manually entered,
              automatically pre-populated, and manually overridden. (For `completed` QuestionnaireResponse)
             - Contains answers for all required items.
          )
        end
        # Test 5: validate the user provided $questionnaire-package response
        test from: :dtr_custom_questionnaire_package_validation
        # Test 6: validate the user provided $next-question questionnaire
        test from: :dtr_custom_next_questionnaire_validation
        # Test 7: verify the custom response has the necessary libraries for pre-population
        test from: :dtr_custom_questionnaire_libraries
        # Test 8: verify the custom response has the necessaru extensions for pre-population
        test from: :dtr_custom_questionnaire_extensions
        # Test 9: verify custom response has necessary expressions for pre-population
        test from: :dtr_custom_questionnaire_expressions
      end

      group do
        title 'Filling Out the Questionnaire'
        description %(
          The tester will interact with the questionnaire within their client system
          such that pre-population steps are taken, the qustionnaire is rendered, and
          they are able to fill it out. The tester will attest that questionnaire pre-population
          and rendering directives were followed.
        )
        test from: :dtr_prepopulation_attestation
        test from: :dtr_prepopulation_override_attestation
      end
    end

    group do
      id :dtr_full_ehr_custom_adaptive_followup_questions
      title 'Retrieving the Next Question (Round 2)'
      description %()
      run_as_group
      config(
        options: {
          accepts_multiple_requests: true,
          next_tag: "custom_followup_#{CLIENT_NEXT_TAG}",
          next_question_prompt_title: 'Follow-up Next Question Request'
        }
      )

      # Test 1: wait for the $next-question request
      test from: :dtr_adaptive_questionnaire_next_question_request
      # Test 2: validate the $next-question request
      test from: :dtr_next_question_request_validation
      # Test 3: validate the QuestionnaireResponse in the input parameter
      test from: :dtr_adaptive_questionnaire_response_validation
      # Test 4: validate the user provided $next-question questionnaire
      test from: :dtr_custom_next_questionnaire_validation
    end

    # This will be omited if custom questionnaire not provided
    group do
      id :dtr_full_ehr_custom_adaptive_followup_questions_2
      title 'Retrieving the Next Question (Round 3)'
      description %()
      run_as_group
      config(
        options: {
          accepts_multiple_requests: true,
          next_tag: "custom_followup_#{CLIENT_NEXT_TAG}",
          next_question_prompt_title: 'Follow-up Next Question Request'
        }
      )

      # Test 1: wait for the $next-question request
      test from: :dtr_adaptive_questionnaire_next_question_request
      # Test 2: validate the $next-question request
      test from: :dtr_next_question_request_validation
      # Test 3: validate the QuestionnaireResponse in the input parameter
      test from: :dtr_adaptive_questionnaire_response_validation
      # Test 4: validate the user provided $next-question questionnaire
      test from: :dtr_custom_next_questionnaire_validation
    end

    group do
      id :dtr_full_ehr_custom_adaptive_completion
      title 'Completing the Adaptive Questionnaire'
      description %()
      run_as_group
      config(
        options: {
          accepts_multiple_requests: true,
          next_tag: "custom_completion_#{CLIENT_NEXT_TAG}",
          next_question_prompt_title: 'Last Next Question Request',
          custom_complete_questionnaire: true
        }
      )

      # Test 1: wait for the $next-question request
      test from: :dtr_adaptive_questionnaire_next_question_request
      # Test 2: validate the $next-question request
      test from: :dtr_next_question_request_validation
      # Test 3: validate the QuestionnaireResponse in the input parameter
      test from: :dtr_adaptive_questionnaire_response_validation
    end
  end
end
