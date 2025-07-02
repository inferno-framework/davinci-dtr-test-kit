require_relative '../../../descriptions'
require_relative '../../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRCustomAdaptiveRequestTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_custom_adative_request
    title 'Client can complete the DTR Adaptive Questionnaire workflow'
    description %(
      This test waits for client requests to retrieve and progress through an adaptive questionnaire workflow.

      1. **Questionnaire Package Request**: The client should invoke the `$questionnaire-package` operation
         to retrieve the adaptive questionnaire package. Inferno will respond with the user-provided
         empty adaptive questionnaire.

      2. **Next Question Requests**: The client should invoke the `$next-question` operation to request
         the next set of questions. Inferno will respond sequentially with the next Questionnaire from
         the user-provided list. If a `$next-question` request is received when the list is empty,
         Inferno will mark the `QuestionnaireResponse` as completed.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@165', 'hl7.fhir.us.davinci-dtr_2.0.1@242',
                          'hl7.fhir.us.davinci-dtr_2.0.1@244'

    config options: { accepts_multiple_requests: true }

    input :custom_questionnaire_package_response, :custom_next_question_questionnaires
    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED

    run do
      assert_valid_json(
        custom_questionnaire_package_response,
        'Custom questionnaire package response is not a valid json'
      )
      assert_valid_json(custom_next_question_questionnaires, 'Custom next questionnaires input is not a valid json')

      custom_qp = JSON.parse(custom_questionnaire_package_response)
      custom_questionnaires = JSON.parse(custom_next_question_questionnaires)
      assert custom_qp.present?, %(
        Custom questionnaire package response is empty, please provide a custom questionnaire package response
        for the $questionnaire-package request
      )
      assert custom_questionnaires.present?, %(
        'Custom questionnaires list is empty, please provide a list of Custom Questionnaire resources
        to include in each $next-question Response.
      )

      wait(
        identifier: client_id,
        message: %(
          ### Adaptive Questionnaire Workflow

          1. **Questionnaire Package Request**:
             - Invoke the `$questionnaire-package` operation by sending a POST request to the following endpoint
               to retrieve the adaptive questionnaire package:

               `#{questionnaire_package_url}`

             - Inferno will respond with the user-provided empty adaptive questionnaire.

          2. **Next Question Requests**:
             - After receiving the questionnaire package, invoke the `$next-question` operation by sending
               a POST request to the following endpoint:

               `#{next_url}`

             - Repeat this request **multiple times**, once for each Questionnaire provided in the user-supplied list.
             - Inferno will sequentially respond with the corresponding Questionnaire from the list.
             - If a `$next-question` request is received when the list is empty, Inferno will mark
               the `QuestionnaireResponse` as completed.

          Inferno will wait for all expected requests to be made.

          ### Continuing the Tests

          Once all required `$next-question` requests have been made,
          [Click here](#{resume_pass_url}?token=#{client_id}) to continue.
        )
      )
    end
  end
end
