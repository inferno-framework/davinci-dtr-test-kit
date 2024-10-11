require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRStaticDinnerLaunchAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_dinner_static_launch_attestation
    title 'Launch DTR for a patient that has an official name (Attestation)'
    description %(
      Attest that DTR has been launched for a patient with data that will be used for prepopulation.
    )

    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that DTR has been launched in the context of a patient with an official name, including
          first and last.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
