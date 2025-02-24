require_relative 'dtr_adaptive_next_question_request_test'
require_relative 'dtr_adaptive_next_question_request_validation_test'
require_relative 'dtr_adaptive_response_validation_test'

module DaVinciDTRTestKit
  class DTRAdaptiveNextQuestionRetrievalGroup < Inferno::TestGroup
    id :dtr_adaptive_next_question_retrieval
    title 'Next Question Request and Validation'
    description %(
      Inferno will wait for the client system to request the next question (or set of questions) using the
      $next-question operation and will return an updated QuestionnaireResponse with a contained Questionnaire
      that includes the next question (or set of questions) for the tester to complete.
      Inferno will then validate the conformance of the request.
    )

    # Test 1: wait for the $next-question request
    test from: :dtr_adaptive_next_question_request
    # Test 2: validate the $next-question request
    test from: :dtr_adaptive_next_question_request_validation
    # Test 3: validate the QuestionnaireResponse in the input parameter
    test from: :dtr_adaptive_response_validation
  end
end
