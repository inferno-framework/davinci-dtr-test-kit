require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRPrepopulationOverrideAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_prepopulation_override_attestation
    title 'Validate the user can override pre-populated data (Attestation)'
    description %(
      Validate that the user can edit a pre-populated item and replace it with another value.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that I have changed the prepopulated value in the First Name field to a new value.

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
