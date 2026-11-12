require_relative '../interaction/interaction_wait_test'
require_relative '../interaction/cql_error_handling_attestation_test'
require_relative '../request/dtr_questionnaire_package_request_validation_test'
require_relative '../response/dtr_questionnaire_package_response_validation_test'
require_relative '../request/dtr_next_question_request_validation_test'
require_relative '../response/dtr_next_question_response_validation_test'
require_relative '../request/dtr_next_question_stopped_after_cql_error_test'
require_relative '../request/dtr_log_questionnaire_errors_request_validation_test'

module DaVinciDTRTestKit
  # Scenario for ID-194: Inferno returns an adaptive Questionnaire and, partway through the
  # $next-question exchange, adds an item whose non-pre-population logic is malformed CQL. The
  # client is expected to stop asking for questions, log the error, and stop the user, so this
  # group does not extend the abstract adaptive group, whose tests expect completed forms.
  class DTRFullEHRV220WorkflowCQLError < Inferno::TestGroup
    title 'CQL Error Handling'
    id :dtr_full_ehr_v220_workflow_cql_error
    description <<~DESCRIPTION
      During this group, the DTR Full EHR will demonstrate that it recognizes problematic CQL in
      Questionnaire logic that is not used for pre-population, stops requesting further questions,
      reports the error to the payer using the `$log-questionnaire-errors` operation, and prohibits
      the user from completing the form.

      Inferno returns an adaptive Questionnaire. Its pre-population logic is valid, but once the
      dinner choice is answered, Inferno's `$next-question` response adds the "Any special requests?"
      item, whose `calculatedExpression` is malformed CQL. Because the error is in questionnaire
      logic rather than pre-population logic, the client is expected to stop rather than continue
      with manual entry (see
      [spec-76](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-76) through
      [spec-81](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-81)).
      Inferno checks mechanically that no `$next-question` request follows the response containing
      the error and that the `$log-questionnaire-errors` request is conformant; the tester attests
      that the user was stopped and that no PHI was logged. The Questionnaire is not counted toward
      Must Support coverage because it is never completed.
    DESCRIPTION
    run_as_group

    INTERACTION_INSTRUCTIONS = <<~TEXT.freeze
      Inferno will wait while the tester uses the system to retrieve the adaptive Questionnaire
      from Inferno's simulated payer server and begin completing it with `$next-question` requests.
      After the dinner choice is answered, Inferno's `$next-question` response adds the
      "Any special requests?" item, whose `calculatedExpression` is malformed CQL (logic that is
      not used for pre-population). The client is expected to recognize the problem, make no
      further `$next-question` requests, report the error to Inferno using the
      `$log-questionnaire-errors` operation, notify the user, and prohibit further completion of
      the form.

      Once the client has reported the error and stopped the user, use the link below to continue.
    TEXT

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'cql_error',
        dtr_exclude_from_questionnaire_must_support: true,
        dtr_interaction_instructions: INTERACTION_INSTRUCTIONS,
        cql_error_item_link_id: '3.3',
        qp_response_template_fixture: File.join('dinner_cql_error',
                                                'parameters_questionnaire_dinner_order_cql_error.json'),
        nq_questionnaire_template_fixture: File.join('dinner_cql_error',
                                                     'dinner_order_cql_error_next_question_template.json')
      }
    )

    group do
      title 'Interaction'
      test from: :dtr_full_ehr_v220_interaction_wait
      test from: :dtr_full_ehr_v220_cql_error_handling_attestation
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
