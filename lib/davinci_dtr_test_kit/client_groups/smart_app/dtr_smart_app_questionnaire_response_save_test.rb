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

    run do
      wait(
        identifier: client_id,
        message: <<~MESSAGE
          Store the completed questionnaire back into the EHR.

          Inferno will wait for a POST request at:

          `#{questionnaire_response_url}`
        MESSAGE
      )
    end
  end
end
