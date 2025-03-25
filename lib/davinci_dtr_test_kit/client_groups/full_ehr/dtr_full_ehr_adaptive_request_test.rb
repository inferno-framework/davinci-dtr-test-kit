require_relative '../../descriptions'
require_relative '../../session_identification'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRAdaptiveRequestTest < Inferno::Test
    include URLs
    include SessionIdentification

    id :dtr_full_ehr_adaptive_request
    title 'Invoke the Questionnaire Package and Initial Next Question Operation'
    description %(
      This test waits for two sequential client requests:

      1. **Questionnaire Package Request**: The client should first invoke the `$questionnaire-package` operation
      to retrieve the adaptive questionnaire package. Inferno will respond to this request with an empty adaptive
      questionnaire.

      2. **Initial Next Question Request**: After receiving the package, the client should invoke the
      `$next-question` operation. Inferno will respond by providing the first set of questions.
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

    run do
      wait_identifier = inputs_to_wait_identifier(client_id, session_url_path)
      qp_endpoint = inputs_to_session_endpont(:questionnaire_package, client_id, session_url_path)
      nq_endpoint = inputs_to_session_endpont(:next_question, client_id, session_url_path)

      wait(
        identifier: wait_identifier,
        message: %(
          ### Adaptive Questionnaire Retrieval

          1. **Questionnaire Package Request**:
            - Invoke the `$questionnaire-package` operation by sending a POST request to the following
            endpoint to retrieve the adaptive questionnaire package:

              `#{qp_endpoint}`.

            - Inferno will respond with an empty adaptive questionnaire.

          2. **Initial Next Question Request**:
            - After receiving the questionnaire package, invoke the `$next-question` operation by sending
            a POST request to the following endpoint to retrieve the first set of questions:

              `#{nq_endpoint}`.

            - Inferno will respond with the initial set of questions.

          Inferno will wait for both of these requests to be made.

          ### Continuing the Tests

          When both requests have been made, [Click here](#{resume_pass_url}?token=#{wait_identifier}) to continue.
        )
      )
    end
  end
end
