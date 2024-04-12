require_relative '../urls'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponseSaveTest < Inferno::Test
    include URLs

    id :dtr_questionnaire_response_save
    title 'Save the QuestionnaireResponse after pre-population'
    description %(
      Inferno, acting as the EHR, will wait for a request to save the QuestionnaireResponse from the client after
      pre-population.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          Save the pre-populated QuestionnaireResponse.

          Inferno will wait for a POST request at:

          `#{questionnaire_response_url}`
        )
      )
    end
  end
end
