require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayerEndpointTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_supported_payer_endpoint
    title 'Client can retrieve payers from supported payer endpoint'
    description %(
      This test verifies that the app can successfully access the supported payer endpoint via a GET request
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
          ### Supported Payer Endpoint

          Inferno will wait for the Light EHR to to make a GET request to

          `#{supported_payer_url(unique_url_id)}`

          Inferno will return the static payers json details

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          a URL segment with value:

          ```
          #{unique_url_id}
          ```
        )
      )
    end
  end
end
