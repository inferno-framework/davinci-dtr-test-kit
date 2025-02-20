require 'securerandom'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRRenderingEnabledQuestionsAttestationTest < Inferno::Test
    include URLs

    id :dtr_rendering_attestation
    title 'Check that the client renders the Questionnaire (Attestation)'
    description %(
      The tester will attest to the ability of the client to appropriately render the
      Questionnaire and allow user interaction.
    )
    run do
      random_id = SecureRandom.uuid
      wait(
        identifier: random_id,
        message: %(
          I attest that the DTR client application has displayed the tester-provided Questionnaire
          appropriately, following all rendering and formating directives within the Questionnaire
          and allowing the user to interact with the questions in the form.

          [Click here](#{resume_pass_url}?token=#{random_id}) if the above statement is **true**.

          [Click here](#{resume_fail_url}?token=#{random_id}) if the above statement is **false**.
        )
      )
    end
  end
end
