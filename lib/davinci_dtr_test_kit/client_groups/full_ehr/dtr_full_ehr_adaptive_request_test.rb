require_relative '../../descriptions'
require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRAdaptiveRequestTest < Inferno::Test
    include URLs

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

    run do
      wait(
        identifier: client_id,
        message: %(
          ### Adaptive Questionnaire Retrieval

          1. **Questionnaire Package Request**:
            - Invoke the `$questionnaire-package` operation by sending a POST request to the following
              endpoint to retrieve the adaptive questionnaire package:

              `#{questionnaire_package_url}`.

            - Inferno will respond with an empty adaptive questionnaire.

          2. **Initial Next Question Request**:
            - After receiving the questionnaire package, invoke the `$next-question` operation by sending
              a POST request to the following endpoint to retrieve the first set of questions:

              `#{next_url}`.

            - Inferno will respond with the initial set of questions.

          Inferno will wait for both of these requests to be made.

          ### Continuing the Tests

          When both requests have been made, [Click here](#{resume_pass_url}?token=#{client_id}) to continue.
        )
      )
    end
  end
end
