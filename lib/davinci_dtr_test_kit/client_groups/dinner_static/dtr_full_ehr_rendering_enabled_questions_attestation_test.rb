require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRStaticDinnerRenderingAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_dinner_static_rendering_enabledQs_attestation
    title 'Check that the client renders enabled questions appropriately (Attestation)'
    description %(
      Validate that the rendering of the questionnaire includes only the "What would you like on..."
      question appropriate for the dinner selection, if made.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that the client application does not display any "What would you like on..."
          questions until I have selected a dinner choice and then only displays the
          "What would you like on..." question relevant for the dinner request:

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
