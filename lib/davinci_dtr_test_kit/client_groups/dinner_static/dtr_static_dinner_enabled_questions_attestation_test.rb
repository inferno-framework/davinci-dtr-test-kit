require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRStaticDinnerEnabledQuestionsAttestationTest < Inferno::Test
    include URLs

    id :dtr_static_dinner_enabled_questions_attest
    title 'Check that the client renders enabled questions appropriately (Attestation)'
    description %(
      Validate that the rendering of the questionnaire includes only the "What would you like on..."
      question appropriate for the dinner selection, if made.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the client application does not display any "What would you like on..."
          questions until I have selected a dinner choice and then only displays the
          "What would you like on..." question relevant for the dinner request:

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
