require 'securerandom'
require_relative '../../../urls'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220ResumeQuestionnaireAttestationTest < Inferno::Test
    include URLs
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_resume_questionnaire_attestation
    title 'Client saves an in-progress QuestionnaireResponse and resumes it later'
    description %(
      During this test, the tester will confirm that the client saved an in-progress QuestionnaireResponse
      and later resumed and completed it.

      To see the specifics of the attested requirements, click the 'View Specification Requirements' link for this test.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-151'

    output :attest_true_url
    output :attest_false_url

    LIST_ENTRY_PREFIX = "\n          - ".freeze

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def requests_to_analyze
      @requests_to_analyze ||= load_tagged_requests(*target_tags)
    end

    def returned_questionnaires_for_display
      requests_to_analyze.each_with_object([]) do |request, questionnaires|
        response_parameters = FHIR.from_contents(request.response_body)
        next unless response_parameters.is_a?(FHIR::Parameters)

        questionnaires.concat(
          questionnaires_from_questionnaire_package_output_parameters(response_parameters)
            .map { |questionnaire| questionnaire_display(questionnaire) }
        )
      rescue JSON::ParserError
        next
      end.uniq
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])
      skip_if no_questionnaires_returned?(requests_to_analyze),
              'No Questionnaire Package requests returned a Questionnaire.'

      identifier = SecureRandom.hex(32)
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_true_url:)
      output(attest_false_url:)

      wait(
        identifier:,
        message: %(
          I attest that during the previous interactions the DTR client application
          - Saved the QuestionnaireResponse with status `in-progress` before it was complete,
            and allowed the user to close the session without losing the answers entered so far.
          - Relaunched DTR from the saved QuestionnaireResponse, restoring the answers entered
            before the session was closed.
          - Allowed the user to complete the resumed QuestionnaireResponse and saved it.

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.

          -------------

          Questionnaires returned during the previous interactions:
          - #{returned_questionnaires_for_display.join(LIST_ENTRY_PREFIX)}
        )
      )
    end
  end
end
