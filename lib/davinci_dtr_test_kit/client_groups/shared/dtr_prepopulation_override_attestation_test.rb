require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRPrepopulationOverrideAttestationTest < Inferno::Test
    include URLs

    id :dtr_prepopulation_override_attest
    title 'Check that the user can manually populate answers in the Questionnaire (Attestation)'
    description %(
      Validate that the user can edit the rendered form to provide answers, including
      - Providing an answer for an unanswered question.
      - Overriding a pre-populated answer with a manual answer.

      Note that at least one pre-populated answer must remain un-altered to demonstrate
      its representation in the resulting QuestionnaireResponse.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the user has done the following while filling out the form:
          - Changed a pre-populated answer to a new value.
          - Provided an answer to a question that was not pre-populated.
          - Left a pre-populated answer unchanged.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
