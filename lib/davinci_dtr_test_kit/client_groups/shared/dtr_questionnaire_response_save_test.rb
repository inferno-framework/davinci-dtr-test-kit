require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponseSaveTest < Inferno::Test
    include URLs

    id :dtr_questionnaire_response_save
    title 'Save the QuestionnaireResponse after completing it'
    description %(
      Inferno, acting as the EHR, will wait for a request to save the QuestionnaireResponse from the client.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
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
