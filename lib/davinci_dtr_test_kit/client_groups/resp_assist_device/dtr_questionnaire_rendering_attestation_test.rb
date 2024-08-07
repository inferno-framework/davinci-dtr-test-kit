require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRQuestionnaireRenderingAttestationTest < Inferno::Test
    include URLs

    id :dtr_questionnaire_rendering_attestation
    title 'Check that the client renders the questionnaire (Attestation)'
    description %(
      Thist test provides the tester an opportunity to observe their client application following the receipt of the
      questionnaire pacakage and attest that the application renders the questionnaire.
    )
    input :client_id

    run do
      load_tagged_requests QUESTIONNAIRE_PACKAGE_TAG
      skip_if request.blank?, 'A Questionnaire Package request must be made prior to running this test'

      wait(
        identifier: client_id,
        message: %(
          I attest that the client application displays the questionnaire and respects the following rendering style:
          - The "Signature" field label is rendered with green text

          [Click here](#{resume_pass_url}?client_id=#{client_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?client_id=#{client_id}) if the above statement is **false**.
        )
      )
    end
  end
end
