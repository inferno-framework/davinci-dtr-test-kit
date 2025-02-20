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

    config options: { accepts_multiple_requests: true }
    input :access_token,
          description: %(
            `Bearer` token that the client under test will send in the
            `Authorization` header of each HTTP request to Inferno. Inferno
            will look for this value to associate requests with this session.
          )

    run do
      wait(
        identifier: access_token,
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

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          Bearer #{access_token}
          ```

          ### Continuing the Tests

          When both requests have been made, [Click here](#{resume_pass_url}?token=#{access_token}) to continue.
        )
      )
    end
  end
end
