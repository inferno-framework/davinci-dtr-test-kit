require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRQuestionnaireRenderingAttestationTest < Inferno::Test
    include URLs

    id :dtr_resp_rendering_attest
    title 'Check that the client renders the questionnaire (Attestation)'
    description %(
      This test provides the tester an opportunity to observe their client application following the receipt of the
      questionnaire package and attest that the application renders the questionnaire.
    )

    run do
      load_tagged_requests QUESTIONNAIRE_PACKAGE_TAG
      skip_if request.blank?, 'A Questionnaire Package request must be made prior to running this test'
      token = SecureRandom.uuid

      wait(
        identifier: token,
        message: %(
          I attest that the client application displays the questionnaire and respects the following rendering style:
          - The "Signature" field label is rendered with green text

          [Click here](#{resume_pass_url}?token=#{token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{token}) if the above statement is **false**.
        )
      )
    end
  end
end
