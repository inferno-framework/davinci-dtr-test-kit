require_relative 'dtr_adaptive_questionnaire_next_question_retrieval_group'

module DaVinciDTRTestKit
  class DTRAdaptiveQuestionnaireCompletionGroup < Inferno::TestGroup
    id :dtr_adaptive_questionnaire_completion
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
