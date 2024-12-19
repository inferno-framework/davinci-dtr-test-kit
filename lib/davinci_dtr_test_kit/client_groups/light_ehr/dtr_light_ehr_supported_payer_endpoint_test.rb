require_relative '../../urls'

module DaVinciDTRTestKit
  class DtrLightEhrSupportedPayerEndpointTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_supported_payer_endpoint
    title 'Client can retrieve payers from supported payer endpoint'
    description %(
      Inferno, will wait for a request to return the payer details from the supported endpoint.
    )
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
          ### Supported Payer Endpoint

          Inferno will wait for the Light EHR to to make a GET request to

          `#{supported_payer_url}`

          Inferno will return the static payers json details

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          Bearer #{access_token}
          ```
        )
      )
    end
  end
end
