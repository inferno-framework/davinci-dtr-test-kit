require_relative '../full_ehr/dtr_full_ehr_adaptive_questionnaire_initial_retrieval_group'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_rendering_group'
require_relative '../shared/dtr_adaptive_questionnaire_next_question_retieval_group'

module DaVinciDTRTestKit
  class DTRFullEHRAdaptiveDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_adaptive_dinner_questionnaire_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This test validates that a DTR Full EHR client can perform a full DTR Adaptive Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate their ability to:

      1. Fetch the adaptive questionnaire package
        ([DinnerOrderAdaptive](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_adaptive/questionnaire_dinner_order_adaptive.json))
      2. Fetch the first set of questions and render and pre-populate them appropriately, including:
         - fetch additional data needed for pre-population
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled
      3. Answer the initial questions and request additional questions
      4. Complete the questionnaire and provide the completed QuestionnaireResponse
         with appropriate indicators for pre-populated and manually-entered data.
    )

    group do
      id :dtr_full_ehr_adaptive_questionnaire_retrieval
      title 'Retrieving the Adaptive Questionnaire'
      description %(
        After DTR launch, Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and follow up with an initial $next-question request to retrieve
        the first set of questions.

        The initial set of questions will be returned for the tester to complete and attest to pre-population
        and questionnaire rendering.

        Inferno will also validate the conformance of the requests.
      )
      run_as_group

      group from: :dtr_full_ehr_adaptive_questionnaire_initial_retrieval
      group from: :dtr_full_ehr_questionnaire_rendering
    end

    group do
      id :dtr_full_ehr_adaptive_questionnaire_followup_questions
      title 'Retrieving the Next Question'
      description %(
        The client makes a subsequent call to request the next question or set of questions
        using the $next-question operation, and including the answers to all required questions
        in the questionnaire to this point.
        Inferno will validate that the request conforms to the [next question operation input parameters profile](http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in)
        and will provide the next questions accordingly for the tester to complete and attest to pre-population
        and questionnaire rendering.
      )

      config(
        options: {
          next_question_prompt_title: 'Follow-up Next Question Request'
        }
      )

      run_as_group

      group from: :dtr_adaptive_questionnaire_next_question_retrieval
      group from: :dtr_full_ehr_questionnaire_rendering
    end

    group do
      id :dtr_full_ehr_adaptive_questionnaire_completion
      title 'Completing the Adaptive Questionnaire'
      description %(
        The client makes a final $next-question call, including the answers to all required questions asked so far.
        Inferno will validate that the request conforms to the [next question operation input parameters profile](http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in)
        and will update the status of the QuestionnaireResponse resource parameter to `complete`.
        Inferno will also validate the completed QuestionnaireResponse conformance.
      )

      config(
        options: {
          next_question_prompt_title: 'Last Next Question Request'
        }
      )
      run_as_group

      group from: :dtr_adaptive_questionnaire_next_question_retrieval
    end
  end
end
