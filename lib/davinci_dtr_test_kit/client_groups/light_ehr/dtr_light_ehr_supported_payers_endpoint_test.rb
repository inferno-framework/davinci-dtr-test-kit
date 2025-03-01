require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayersEndpointTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_sp_endpoint
    title 'Client can retrieve payers from supported payer endpoint'
    description %(
      This test verifies that the app can successfully access the supported payer endpoint via a GET request
    )
    input :unique_url_id,
          title: 'Supported Payers Endpoint Path',
          description: %(
            A unique identifier that will be used to construct the supported payers
            endpoint URL. This allows a permanent configuration for the tester to
            use across Inferno sessions.
          )
    input :user_response,
          title: 'Custom Supported Payers Response',
          description: %(
            A response from the user for a payer information in JSON
          ),
          optional: true,
          type: 'textarea'

    run do
      wait(
        identifier: unique_url_id,
        message: %(
          ### Supported Payer Endpoint

          Inferno will wait for the Light EHR to to make a GET request to

          `#{supported_payer_url(unique_url_id)}`

          Inferno will return the static payers json details
        )
      )
    end
  end
end
