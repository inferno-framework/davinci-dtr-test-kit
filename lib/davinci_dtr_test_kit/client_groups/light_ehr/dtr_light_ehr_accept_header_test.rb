require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRAcceptHeaderTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_accept_header
    title 'Checks accept header for supported payer endpoint'
    description %(
      This test verifies that the request to the supported payer endpoint
      includes an Accept header set to application/json.
    )
    input :unique_url_id,
          description: %(
            A unique identifier that will be used to construct the supported payers
            endpoint URL. This allows a permanent configuration for the tester to
            use across Inferno sessions.
          )

    run do
      wait(
        identifier: unique_url_id,
        message: %(
          ### Accept Header Check

          Inferno will wait for the Light EHR to make a GET request to

          `#{supported_payer_url(unique_url_id)}`

          with an `Accept` header set to `application/json`.

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          #{unique_url_id}
          ```
        )
      )

      raise 'Accept header must be application/json' if request.headers['Accept'] != 'application/json'

      pass 'Accept header is correctly set to application/json'
    end
  end
end
