require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRAdaptiveQuestionnaireNextQuestionRequestTest < Inferno::Test
    include URLs

    id :dtr_adaptive_questionnaire_next_question_request
    title 'Invoke the $next-question operation'
    description %(
      Inferno will wait for the client to invoke the $next-question operation to retrieve the next question
      or set of questions.
      Inferno will validate the request body and update the contained Questionnaire to include
      the next question or set of questions.
    )

    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          ### Next Question Request

          Inferno will wait for the client to invoke the $next-question operation by sending a POST
          request to

          `#{next_url}`

          Upon receipt, Inferno will provide the next question or set of questions to complete.

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          Bearer #{access_token}
          ```
        )
      )
    end
  end
end
