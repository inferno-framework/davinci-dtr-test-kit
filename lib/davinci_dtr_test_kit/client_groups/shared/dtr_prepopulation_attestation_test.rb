require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRPrepopulationAttestationTest < Inferno::Test
    include URLs

    id :dtr_prepopulation_attest
    title 'Check that the client pre-populates the Questionnaire (Attestation)'
    description %(
      Validate that pre-population of patient's information occurs as expected.

      Note that the test requires that two questions be pre-populated so that both a pre-populated
      and an overridden answer can be demonstrated when the QuestionnaireResponse is generated.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the DTR application has automatically filled in at least two questions with
          values determined by the questionnaire's pre-population logic executed on data in the EHR.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
