require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRSmartAppStaticDinnerPrepopulationOverrideAttestationTest < Inferno::Test
    include URLs

    id :dtr_smart_app_dinner_static_prepopulation_override_attestation
    title 'Validate the user can override pre-populated data (Attestation)'
    description %(
      Validate that the user can edit a pre-populated item and replace it with another value.
    )

    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that

          1. The client pre-populated an answer for question 'Location'.
          2. I have changed the answer to a different value.

          [Click here](#{resume_pass_url}?client_id=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?client_id=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
