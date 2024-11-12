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

    def example_client_jwt_payload_part
      Base64.strict_encode64({ inferno_client_id: access_token }.to_json).delete('=')
    end

    def request_identification
      if config.options[:smart_app]
        "eyJhbGciOiJub25lIn0.#{example_client_jwt_payload_part}"
      else
        access_token
      end
    end

    def cont_test_description
      <<~DESCRIPTION
        ### Continuing the Tests

        When the DTR application has finished loading the Questionnaire,
        including any clinical data requests to support pre-population,
        [Click here](#{resume_pass_url}?client_id=#{access_token}) to continue.
      DESCRIPTION
    end

    run do
      next_question_prompt_title = config.options[:next_question_prompt_title]
      prompt_cont = if next_question_prompt_title&.include?('Initial')
                      %(Upon receipt, Inferno will provide the first set of questions to complete.)
                    elsif next_question_prompt_title&.include?('Last')
                      %(Upon receipt, Inferno will update the status of the QuestionnaireResponse
                      resource parameter to `complete`.)
                    else
                      %(Upon receipt, Inferno will provide the next set of questions to complete
                      based on previous answers.)
                    end

      wait(
        identifier: access_token,
        message: <<~MESSAGE
          ### #{next_question_prompt_title}

          Inferno will wait for the client to invoke the $next-question operation by sending a POST
          request to

          `#{next_url}`

          #{prompt_cont}

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          Bearer #{request_identification}
          ```

          #{cont_test_description if config.options[:accepts_multiple_requests]}
        MESSAGE
      )
    end
  end
end
