require_relative 'dtr_adaptive_next_question_retrieval_group'

module DaVinciDTRTestKit
  class DTRAdaptiveFollowupQuestionsGroup < Inferno::TestGroup
    id :dtr_adaptive_followup_questions
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

    group from: :dtr_adaptive_next_question_retrieval
  end
end
