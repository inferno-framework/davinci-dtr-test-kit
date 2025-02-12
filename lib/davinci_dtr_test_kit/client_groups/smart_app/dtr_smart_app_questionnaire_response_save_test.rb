require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRSmartAppQuestionnaireResponseSaveTest < Inferno::Test
    include URLs

    id :dtr_smart_app_questionnaire_response_save
    title 'Save the QuestionnaireResponse after completing it'
    description %(
      Inferno, acting as the EHR, will wait for a request to save the QuestionnaireResponse from the client.
    )
    input :client_id

    def prompt
      if config.options[:adaptive] || config.options[:custom]
        'Store the completed questionnaire back into the EHR.'
      else
        <<~DESCRIPTION
          Complete the questionnaire, leaving the following items unmodified, because a subsequent test will expect
          their pre-populated values:

          - First Name
          - Last Name
        DESCRIPTION
      end
    end

    run do
      wait(
        identifier: client_id,
        message: <<~MESSAGE
          #{prompt}

          Inferno will wait for a POST request at:

          `#{questionnaire_response_url}`
        MESSAGE
      )
    end
  end
end
