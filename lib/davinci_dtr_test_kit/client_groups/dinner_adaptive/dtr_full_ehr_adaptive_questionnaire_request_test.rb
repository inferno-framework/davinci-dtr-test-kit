require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRAdaptiveQuestionnaireRequestTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_adaptive_questionnaire_request
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
    input :access_token

    run do
      wait(
        identifier: access_token,
        message: %(
          ### Questionnaire Retrieval

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

          When both requests have been made, [Click here](#{resume_pass_url}?token=#{access_token}) to continue.
        )
      )
    end
  end
end