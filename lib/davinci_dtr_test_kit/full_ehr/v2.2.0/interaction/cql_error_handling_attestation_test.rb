require 'securerandom'
require_relative '../../../urls'
require_relative '../../../tags'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220CQLErrorHandlingAttestationTest < Inferno::Test
    include URLs
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_cql_error_handling_attestation
    title 'Client stops form completion and logs the CQL error without PHI'
    description %(
      During this test, the tester confirms how the client handled the malformed CQL that Inferno's
      simulated payer server returned in a `$next-question` response during the previous
      interaction. The error is in a `calculatedExpression`, which is logic that is not used for
      pre-population, so the client cannot fall back to manual entry of the affected answers.
      Whether the client stopped making `$next-question` requests is checked mechanically, but
      Inferno cannot observe the client's user interface or its own logs, so the tester attests that:

      - The client notified the user that there is an issue with the Questionnaire and prohibited
        further completion of the form
        ([spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)).
      - The OperationOutcome sent in the `$log-questionnaire-errors` request did not contain
        information about the response or information retrieved from FHIR APIs that could
        potentially include PHI
        ([oper-2](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html#ci-c-oper-2)).

      The conformance of the `$log-questionnaire-errors` request itself is checked mechanically in
      a separate test.
    )

    output :attest_true_url
    output :attest_false_url

    def target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def requests_to_analyze
      @requests_to_analyze ||= load_tagged_requests(*target_tags)
    end

    def returned_questionnaires_for_display
      questionnaires_from_operation_responses(requests_to_analyze)
        .map { |questionnaire| questionnaire_display(questionnaire) }
        .uniq
    end

    LIST_ENTRY_PREFIX = "\n          - ".freeze

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
        identifier: identifier,
        message: %(
          I attest that, for the Questionnaire(s) returned by Inferno during the previous
          interaction (listed below), the DTR client application
          - Recognized the malformed CQL in the `calculatedExpression` of the item returned by
            `$next-question` and did not attempt to execute it.
          - Notified the user that there is an issue with the Questionnaire and prohibited
            further completion of the form (see
            [spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)).
          - Reported the error using `$log-questionnaire-errors` with an OperationOutcome that
            does not contain information about the response or information retrieved from FHIR
            APIs that could potentially include PHI (see
            [oper-2](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html#ci-c-oper-2)).

          [Click here](#{attest_true_url}) if the above statement is **true**.

          [Click here](#{attest_false_url}) if the above statement is **false**.

          -------------

          Questionnaires returned during the previous interaction:
          - #{returned_questionnaires_for_display.join(LIST_ENTRY_PREFIX)}
        )
      )
    end
  end
end
