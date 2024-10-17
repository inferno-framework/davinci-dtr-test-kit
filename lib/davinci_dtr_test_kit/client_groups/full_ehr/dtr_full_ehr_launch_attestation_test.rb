require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRLaunchAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_launch_attestation
    title 'Launch DTR for a patient that has an official name (Attestation)'
    description %(
      Attest that DTR has been launched for a patient with data that will be used for prepopulation.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that DTR has been launched in the context of a patient with an official name, including
          first and last.

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
