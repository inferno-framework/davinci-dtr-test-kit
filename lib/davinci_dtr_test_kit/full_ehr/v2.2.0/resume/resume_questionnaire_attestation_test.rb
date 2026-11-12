require 'securerandom'
require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220ResumeQuestionnaireAttestationTest < Inferno::Test
    include URLs
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_resume_questionnaire_attestation
    title 'Client saves an in-progress QuestionnaireResponse and resumes it later'
    description %(
      During this test, the tester will confirm that the Health IT module saved the in-progress
      QuestionnaireResponse and let the user close the DTR session and relaunch it later from the
      saved QuestionnaireResponse. Inferno can't see the client's storage, so it relies on the tester
      for these. The answers kept after resuming and the completed QuestionnaireResponse are checked
      from the $next-question requests in an earlier test.

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

    run do
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
          - Saved the QuestionnaireResponse with status `in-progress` before it was complete.
          - Allowed the user to close the DTR session and later relaunch it from the saved
            QuestionnaireResponse, rather than continuing the original session.

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.

          -------------

          Questionnaires returned during the previous interactions:
          - #{returned_questionnaires_for_display(requests_to_analyze).join(LIST_ENTRY_PREFIX)}
        )
      )
    end
  end
end
