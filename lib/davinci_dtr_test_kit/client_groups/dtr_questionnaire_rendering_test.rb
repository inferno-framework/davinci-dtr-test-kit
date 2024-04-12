require_relative '../urls'

module DaVinciDTRTestKit
  class DTRQuestionnaireRenderingTest < Inferno::Test
    include URLs

    id :dtr_questionnaire_rendering
    title 'Check that the client renders the questionnaire (Attestation)'
    description %(
      Thist test provides the tester an opportunity to observe their client application following the receipt of the
      questionnaire pacakage and attest that the application renders the questionnaire.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that the client application displays the questionnaire and respects the following rendering style:
          - The "Signature" field label is rendered with green text

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
