require 'securerandom'
require_relative '../../../urls'
require_relative '../../short_circuit_interaction_verification'

module DaVinciDTRTestKit
  class DTRFullEHRV220UIDisplayAndInteractionAttestationTest < Inferno::Test
    include URLs
    include ShortCircuitInteractionVerification

    id :dtr_full_ehr_v220_ui_display_and_interaction
    title 'Client correctly displays and allows users to interact with the questionnaire(s)'
    description %(
      The tester will attest to the ability of the client to appropriately render the
      Questionnaire and allow user interaction.
    )

    output :attest_true_url
    output :attest_false_url

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])

      # first check that there were successful $questionnaire-package requests
      requests = load_tagged_requests(*target_tags)
      skip_if requests.none? { |request| request.status.to_s.starts_with?('2') },
              'No successful Questionnaire Package requests received.'

      identifier = SecureRandom.hex(32)
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_true_url:)
      output(attest_false_url:)

      wait(
        identifier: identifier,
        message: %(
          I attest that the DTR client application has displayed Questionnaire
          appropriately, following all rendering and formatting directives within the Questionnaire
          and allowing the user to interact with the questions in the form.

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.
        )
      )
    end
  end
end
