require_relative '../../../descriptions'
require_relative '../../../session_identification'
require_relative '../../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRCustomAdaptiveRequestTest < Inferno::Test
    include URLs
    include SessionIdentification

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
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@165', 'hl7.fhir.us.davinci-dtr_2.0.1@262',
                          'hl7.fhir.us.davinci-dtr_2.0.1@264'

    config options: { accepts_multiple_requests: true }
    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED
    input :session_url_path,
          title: 'Session-specific URL path extension',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_SESSION_URL_PATH_LOCKED
    input :smart_jwk_set,
          title: 'JSON Web Key Set (JWKS)',
          type: 'textarea',
          optional: true,
          locked: true,
          description: INPUT_JWK_SET_LOCKED
    input :custom_questionnaire_package_response, :custom_next_question_questionnaires

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

      wait_identifier = inputs_to_wait_identifier(client_id, session_url_path)
      qp_endpoint = inputs_to_session_endpont(:questionnaire_package, client_id, session_url_path)
      nq_endpoint = inputs_to_session_endpont(:next_question, client_id, session_url_path)
      wait(
        identifier: wait_identifier,
        message: %(
          ### Adaptive Questionnaire Workflow

          1. **Questionnaire Package Request**:
             - Invoke the `$questionnaire-package` operation by sending a POST request to the following endpoint
               to retrieve the adaptive questionnaire package:

               `#{qp_endpoint}`

             - Inferno will respond with the user-provided empty adaptive questionnaire.

          2. **Next Question Requests**:
             - After receiving the questionnaire package, invoke the `$next-question` operation by sending
               a POST request to the following endpoint:

               `#{nq_endpoint}`

             - Repeat this request **multiple times**, once for each Questionnaire provided in the user-supplied list.
             - Inferno will sequentially respond with the corresponding Questionnaire from the list.
             - If a `$next-question` request is received when the list is empty, Inferno will mark
               the `QuestionnaireResponse` as completed.

          Inferno will wait for all expected requests to be made.

          ### Continuing the Tests

          Once all required `$next-question` requests have been made,
          [Click here](#{resume_pass_url}?token=#{wait_identifier}) to continue.
        )
      )
    end
  end
end
