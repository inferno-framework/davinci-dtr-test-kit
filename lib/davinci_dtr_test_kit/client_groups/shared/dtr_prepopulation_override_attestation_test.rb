require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRPrepopulationOverrideAttestationTest < Inferno::Test
    include URLs

    id :dtr_prepopulation_override_attestation
    title 'Validate the user can override pre-populated data (Attestation)'
    description %(
      Validate that the user can edit a pre-populated item and replace it with another value.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that I have changed the prepopulated value in a questionnaire field to a new value.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
