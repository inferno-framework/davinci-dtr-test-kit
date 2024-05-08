require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRStaticDinnerPrepopulationOverrideAttestationTest < Inferno::Test
    include URLs

    id :dtr_dinner_static_prepopulation_override_attestation
    title 'Validate the user can override pre-populated data (Attestation)'
    description %(
      Validate that the user can edit a pre-populated item and replace it with another value.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that

          1. The client pre-populated an answer for question 'Location'.
          2. I have changed the answer to a different value.

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
