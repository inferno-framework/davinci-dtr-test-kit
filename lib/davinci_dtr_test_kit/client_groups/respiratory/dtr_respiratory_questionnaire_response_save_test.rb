require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRRespiratoryQuestionnaireResponseSaveTest < Inferno::Test
    include URLs

    id :dtr_resp_qr_save
    title 'Save the QuestionnaireResponse after completing it'
    description %(
      Inferno, acting as the EHR, will wait for a request to save the QuestionnaireResponse from the client.
    )
    input :client_id

    run do
      wait(
        identifier: client_id,
        message: %(
          Complete the questionnaire, leaving the following items unmodified, because a subsequent test will expect
          their pre-populated values:

          - Last Name
          - Patient diagnoses for order

          Inferno will wait for a POST request at:

          `#{questionnaire_response_url}`
        )
      )
    end
  end
end
