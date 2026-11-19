require_relative '../interaction/interaction_wait_test'
require_relative '../request/dtr_questionnaire_package_request_validation_test'
require_relative '../response/dtr_questionnaire_package_response_validation_test'
require_relative '../request/dtr_next_question_request_validation_test'
require_relative '../response/dtr_next_question_response_validation_test'
require_relative 'dtr_next_question_stopped_after_cql_error_test'
require_relative '../request/dtr_log_questionnaire_errors_request_validation_test'

module DaVinciDTRTestKit
  # Scenario for ID-194: Inferno returns a two-stage adaptive Questionnaire. The first
  # $next-question response asks for one manually entered answer; the second adds an item whose
  # non-pre-population logic is malformed CQL. The client is expected to stop asking for
  # questions, log the error, and stop the user, so this group does not extend the abstract
  # adaptive group, whose tests expect completed forms.
  class DTRFullEHRV220WorkflowCQLError < Inferno::TestGroup
    title 'CQL Error Handling'
    id :dtr_full_ehr_v220_workflow_cql_error
    description <<~DESCRIPTION
      During this group, the DTR client will demonstrate that it recognizes problematic CQL in
      Questionnaire logic that is not used for pre-population, stops requesting further questions,
      reports the error to the payer using the `$log-questionnaire-errors` operation, and prohibits
      the user from completing the form.

      Inferno returns its CQL Error Questionnaire, a two-stage adaptive Questionnaire. The first
      `$next-question` response asks for a single manually entered answer. Once it is answered, the
      next `$next-question` response adds a read-only summary item whose `calculatedExpression` is
      malformed CQL. Because the error is in questionnaire logic rather than pre-population logic,
      the client is expected to stop rather than continue with manual entry (see
      [spec-76](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-76) through
      [spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)).
      Inferno checks that no `$next-question` request follows the response containing the error and
      that the `$log-questionnaire-errors` request is conformant. By continuing past the wait, the
      tester attests that the user was notified and stopped and that no PHI was logged. The
      Questionnaire is not counted toward Must Support coverage because it is never completed.
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
          Inferno will wait while the tester uses the system to retrieve Inferno's CQL Error
          Questionnaire from Inferno's simulated payer server and begin completing it. The
          Questionnaire is not expected to be completed:
          - Launch DTR and retrieve the Questionnaire. The first `$next-question` response asks for
            a single manually entered answer.
          - Answer it. The next `$next-question` response adds a read-only item whose
            `calculatedExpression` is malformed CQL. This logic is not used for pre-population, so
            the client cannot fall back to manual entry of the affected answer.
          - The client is expected to recognize the problem, make no further `$next-question`
            requests, report the error to Inferno using `$log-questionnaire-errors`, notify the
            user, and prohibit further completion of the form.

          **By clicking to continue, you attest** that the client notified the user that there is an
          issue with the Questionnaire and prohibited further completion of the form
          ([spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)),
          and that the OperationOutcome sent in the `$log-questionnaire-errors` request did not
          contain information about the response or information retrieved from FHIR APIs that could
          potentially include PHI
          ([oper-2](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html#ci-c-oper-2)).

          Once the client has reported the error and stopped the user, [click here](%<continuation_url>s)
          to continue and attest.
        MESSAGE
      }
    )

    group do
      title 'Interaction'

      test from: :dtr_full_ehr_v220_interaction_wait,
           title: 'Retrieve the Questionnaire and stop at the CQL error',
           description: %(
             Inferno will act as a Payer DTR Server while the tester launches DTR, retrieves the CQL
             Error Questionnaire, and answers its first question, after which the client stops the
             user because the next `$next-question` response contains malformed CQL. By continuing
             past the wait, the tester attests that the user was notified and prohibited from
             completing the form, and that the logged OperationOutcome contains no PHI.
           ) do
        verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-81', 'hl7.fhir.us.davinci-dtr_2.2.0@oper-2-B'
      end
    end

    group do
      title '$questionnaire-package'

      test from: :dtr_full_ehr_v220_qp_request_validation
      test from: :dtr_full_ehr_v220_qp_response_validation
    end

    group do
      title '$next-question'

      test from: :dtr_full_ehr_v220_nq_request_validation
      test from: :dtr_full_ehr_v220_nq_response_validation
      test from: :dtr_full_ehr_v220_nq_stopped_after_cql_error
    end

    group do
      title '$log-questionnaire-errors'

      test from: :dtr_full_ehr_v220_log_errors_request_validation
    end
  end
end
