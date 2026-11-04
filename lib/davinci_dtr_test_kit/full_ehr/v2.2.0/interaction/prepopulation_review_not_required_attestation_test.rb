require 'securerandom'
require_relative '../../../urls'
require_relative '../../../tags'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220PrepopulationReviewNotRequiredAttestationTest < Inferno::Test
    include URLs
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_prepopulation_review_not_required_attestation
    title 'Users are not required to review pre-populated answers'
    description %(
      The DTR client must give providers the ability, but not a requirement, to review and revise
      pre-populated answers. The previous test showed that a pre-populated answer could be changed
      (`override`) and that one could be left alone (`auto-client`). Inferno cannot see whether the
      client forced the user to explicitly review or acknowledge pre-populated answers before moving on,
      so the tester attests to that here.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-132'

    output :attest_true_url
    output :attest_false_url

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])

      # Only ask for the attestation if a Questionnaire was actually returned for the tester to complete
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?
      skip_if no_questionnaires_returned?(load_tagged_requests(*tags)),
              'No Questionnaire Package requests returned a Questionnaire.'

      identifier = SecureRandom.hex(32)
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_true_url:)
      output(attest_false_url:)

      wait(
        identifier:,
        message: %(
          I attest that while completing the Questionnaire during the previous interaction, the user
          was **not** required to explicitly review, acknowledge, or confirm pre-populated answers,
          either one at a time or all at once, before moving on to the next questions or completing
          the Questionnaire.

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.
        )
      )
    end
  end
end
