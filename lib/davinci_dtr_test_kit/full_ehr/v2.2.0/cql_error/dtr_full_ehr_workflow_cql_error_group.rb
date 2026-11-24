require_relative '../dtr_full_ehr_abstract_adaptive_group'
require_relative 'dtr_next_question_stopped_after_cql_error_test'
require_relative 'log_questionnaire_errors_no_phi_attestation_test'
require_relative '../request/dtr_log_questionnaire_errors_request_validation_test'

module DaVinciDTRTestKit
  # Scenario for ID-194: Inferno returns a two-stage adaptive Questionnaire. The first
  # $next-question response asks for one manually entered answer; the second adds a required item
  # whose non-pre-population logic is malformed CQL. The client is expected to stop asking for
  # questions, log the error, and stop the user. The form is never completed, so the standard
  # adaptive group is used without its rendering attestation and completion check, and the group
  # is excluded from Must Support coverage.
  class DTRFullEHRV220WorkflowCQLError < DTRFullEHRV220AbstractAdaptive
    title 'CQL Error Handling'
    id :dtr_full_ehr_v220_workflow_cql_error
    description <<~DESCRIPTION
      During this group, the DTR client will demonstrate that it recognizes problematic CQL in
      Questionnaire logic that is not used for pre-population, stops requesting further questions,
      reports the error to the payer using the `$log-questionnaire-errors` operation, and prohibits
      the user from completing the form.

      Inferno returns its CQL Error Questionnaire, a two-stage adaptive Questionnaire. The first
      `$next-question` response asks for a single manually entered answer. Once it is answered, the
      next `$next-question` response adds a required, read-only item whose `calculatedExpression`
      is malformed CQL. Because the error is in questionnaire logic rather than pre-population
      logic, the client is expected to stop rather than continue with manual entry (see
      [spec-76](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-76) through
      [spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)).
      Inferno checks that the `$questionnaire-package` and `$next-question` exchanges are
      conformant, that no `$next-question` request follows the response containing the error, and
      that the `$log-questionnaire-errors` request is conformant. The tester attests that the user
      was notified and stopped, and separately that no PHI was logged. The Questionnaire is not
      counted toward Must Support coverage because it is never completed.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'cql_error',
        dtr_exclude_from_questionnaire_must_support: true,
        qp_response_template_fixture: File.join('cql_error', 'parameters_questionnaire_cql_error.json'),
        nq_questionnaire_template_fixture: File.join('cql_error', 'cql_error_next_question_template.json'),
        interaction_message: <<~MESSAGE
          Inferno will wait while the tester uses the system to begin completion of Inferno's CQL Error
          Questionnaire. The Questionnaire is not expected to be completed:
          - Launch DTR, complete the first question, and continue the form.
          - The second question is populated by CQL calculation logic that is malformed. The DTR
            client must notify the user that the Questionnaire cannot be completed.

          Once the client has reported the error and stopped the user, attest to the following
          statement to continue: the client notified the user that there is an issue with the
          Questionnaire and prohibited further completion of the form.

          [Click here](%<continuation_url>s) if the above statement is **true**.

          [Click here](%<attest_false_url>s) if the above statement is **false**.
        MESSAGE
      }
    )

    interaction_group, _package_group, next_question_group = groups

    # The form is never completed, so the rendering attestation and the completion check of the
    # standard adaptive group don't apply.
    interaction_group.remove :dtr_full_ehr_v220_ui_display_and_interaction
    interaction_group.remove :dtr_full_ehr_v220_adaptive_questionnaires_completed
    interaction_group.replace :dtr_full_ehr_v220_interaction_wait, :dtr_full_ehr_v220_interaction_wait do
      id :dtr_full_ehr_v220_cql_error_interaction_wait
      title 'Retrieve the Questionnaire and stop at the CQL error'
      description %(
        Inferno will act as a Payer DTR Server while the tester launches DTR, retrieves the CQL
        Error Questionnaire, and answers its first question, after which the client is expected
        to stop the user because the next `$next-question` response contains malformed CQL. To
        continue, the tester attests whether the user was notified and prohibited from completing
        the form. Attesting false fails this test, and the remaining tests are still evaluated.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-81'
    end

    next_question_group.test from: :dtr_full_ehr_v220_nq_stopped_after_cql_error

    group do
      title '$log-questionnaire-errors'

      test from: :dtr_full_ehr_v220_log_errors_request_validation
      test from: :dtr_full_ehr_v220_log_errors_no_phi_attestation
    end
  end
end
