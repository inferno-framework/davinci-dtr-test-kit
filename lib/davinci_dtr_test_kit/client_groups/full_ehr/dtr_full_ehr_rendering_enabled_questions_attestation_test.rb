require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRRenderingEnabledQuestionsAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_rendering_enabled_questions_attestation
    title 'Check that the client renders enabled questions appropriately (Attestation)'
    description %(
      'Enabled questions' refer to questions that are active, visible, and ready for
      interaction based on certain conditions or rules. These conditions might depend
      on responses to previous questions, the user's role, or other logic defined in
      the questionnaire's configuration. For example:

      - A question becomes "enabled" if a specific answer is given to a prior question
      (e.g., selecting "Yes" to "Do you have any allergies?" enables a follow-up question
      asking for details about the allergies).
      - A question is always "enabled" if no conditional logic restricts it.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that if there are enabled questions in the questionnaire, the client renders them appropriately.
          This includes displaying them in a clear, interactive, and logical order that aligns with the questionnaire's
          structure and logic, ensuring users can respond accurately and without confusion.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
