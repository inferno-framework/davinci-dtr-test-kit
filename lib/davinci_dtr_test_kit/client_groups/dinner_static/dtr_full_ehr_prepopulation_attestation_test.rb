require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRStaticDinnerPrepopulationAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_dinner_static_rendering_prepopulation_attestation
    title 'Check that the client pre-populates the questionnaire (Attestation)'
    description %(
      Validate that pre-population of patient name information occurs as expected.
    )
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          I attest that the DTR application pre-populates the following questions with the respective
          value for the official name of the patient:
          - Last Name
          - First Name

          [Click here](#{resume_pass_url}?token=#{access_token}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{access_token}) if the above statement is **false**.
        )
      )
    end
  end
end
