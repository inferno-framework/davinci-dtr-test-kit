require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRSmartAppPrepopulationAttestationTest < Inferno::Test
    include URLs

    id :dtr_smart_app_prepopulation_attest
    title 'Check that the client pre-populates the questionnaire (Attestation)'
    description %(
      Validate that pre-population of patient name information occurs as expected.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the client application pre-populates the following questions with the respective values:
          - Last Name: Oster
          - First Name: William

          [Click here](#{resume_pass_url}?client_id=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?client_id=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
