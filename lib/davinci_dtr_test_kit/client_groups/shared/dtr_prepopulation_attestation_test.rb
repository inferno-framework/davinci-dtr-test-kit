require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRPrepopulationAttestationTest < Inferno::Test
    include URLs

    id :dtr_prepopulation_attestation
    title 'Check that the client pre-populates the questionnaire (Attestation)'
    description %(
      Validate that pre-population of patient's information occurs as expected.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the DTR application is able to pre-populate questions on the questionnaire
          with relevant information.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
