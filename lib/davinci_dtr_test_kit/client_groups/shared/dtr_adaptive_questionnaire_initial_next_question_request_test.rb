require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRAdaptiveQuestionnaireInitialNextQuestionRequestTest < Inferno::Test
    include URLs

    id :dtr_adaptive_questionnaire_initial_next_question_request
    title 'Invoke the initial $next-question operation'
    description %(
      Inferno will wait for the client to invoke the $next-question operation to retrieve the initial set of questions.
      Inferno will validate the request body and return the initial questionnaire.
    )

    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          ### Initial Next Question Request

          Inferno will wait for the client to invoke the $next-question operation by sending a POST
          request to

          `#{next_url}`

          Upon receipt, Inferno will respond with the initial set of questions.

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
