require_relative '../../descriptions'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRAdaptiveNextQuestionRequestTest < Inferno::Test
    include URLs

    id :dtr_adaptive_next_question_request
    title 'Invoke the $next-question operation'
    description %(
      Inferno will wait for the client to invoke the $next-question operation to retrieve the next question
      or set of questions.
      Inferno will validate the request body and update the contained Questionnaire to include
      the next question or set of questions.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@244'

    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED

    def cont_test_description
      <<~DESCRIPTION
        ### Continuing the Tests

        When the DTR application has finished loading the Questionnaire,
        including any clinical data requests to support pre-population,
        [Click here](#{resume_pass_url}?token=#{client_id}) to continue.
      DESCRIPTION
    end

    def next_question_prompt_title
      config.options[:next_question_prompt_title]
    end

    def next_question_prompt
      if next_question_prompt_title&.include?('Initial')
        'Invoke the $next-question operation by sending a POST request to'
      elsif next_question_prompt_title&.include?('Last')
        'Answer the remaining questions and then make a final next-question request by sending a POST request to'
      else
        "Answer the 'What do you want for dinner' question and then make a next-question request by sending a POST " \
          'request to'
      end
    end

    def prompt_cont
      if next_question_prompt_title&.include?('Initial')
        %(Upon receipt, Inferno will provide the first set of questions to complete.)
      elsif next_question_prompt_title&.include?('Last')
        %(Upon receipt, Inferno will update the status of the QuestionnaireResponse
        resource parameter to `complete`.)
      else
        %(Upon receipt, Inferno will provide the next set of questions to complete
        based on previous answers.)
      end
    end

    run do
      wait(
        identifier: client_id,
        message: <<~MESSAGE
          ### #{next_question_prompt_title}

          #{next_question_prompt}

          `#{next_url}`

          #{prompt_cont}

          #{cont_test_description if config.options[:accepts_multiple_requests]}
        MESSAGE
      )
    end
  end
end
