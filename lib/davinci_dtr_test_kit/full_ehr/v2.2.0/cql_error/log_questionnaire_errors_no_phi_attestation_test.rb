require 'securerandom'
require_relative '../../../urls'
require_relative '../../../tags'

module DaVinciDTRTestKit
  class DTRFullEHRV220LogQuestionnaireErrorsNoPHIAttestationTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_v220_log_errors_no_phi_attestation
    title 'Logged errors do not contain PHI'
    description %(
      The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html#ci-c-oper-2)
      that the OperationOutcome sent with `$log-questionnaire-errors` not contain information about
      the response or information retrieved from FHIR APIs that could potentially include PHI.

      Inferno cannot tell where the logged details came from, so during this test the tester
      attests that the OperationOutcome(s) the client sent during the interaction contain no such
      information. The test is skipped if no `$log-questionnaire-errors` request was made.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-2-B'

    output :attest_true_url
    output :attest_false_url

    def target_tags
      tags = [CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      skip_if load_tagged_requests(*target_tags).blank?,
              'A $log-questionnaire-errors request must be made prior to running this test'

      identifier = SecureRandom.hex(32)
      attest_true_url = "#{resume_pass_url}?token=#{identifier}"
      attest_false_url = "#{resume_fail_url}?token=#{identifier}"
      output(attest_true_url:)
      output(attest_false_url:)

      wait(
        identifier:,
        message: <<~MESSAGE
          I attest that the OperationOutcome(s) the DTR client sent to Inferno using
          `$log-questionnaire-errors` during the previous interaction do **not** contain information
          about the response or information retrieved from FHIR APIs that could potentially
          include PHI.

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.
        MESSAGE
      )
    end
  end
end
