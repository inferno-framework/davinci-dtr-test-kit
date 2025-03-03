require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayersEndpointTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_sp_endpoint
    title 'Client can request an app's supported payers list'
    description %(
      This test verifies that the app can successfully access the supported payers endpoint via a GET request
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
            If present, the value will be returned when the client makes a request to the supported payers endpoint,
            allowing testers to instruct Inferno how to respond with payers that are configured in the
            system under test. The provided response will be checked for conformance to the required
            JSON structure. If not provided, Inferno will return a pre-configured value.
          ),
          optional: true,
          type: 'textarea'

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@104', 'hl7.fhir.us.davinci-dtr_2.0.1@107'

    run do
      wait(
        identifier: unique_url_id,
        message: %(
          ### Supported Payer Endpoint

          Inferno will wait for the Light EHR to to make a GET request to

          `#{supported_payer_url(unique_url_id)}`
        )
      )
    end
  end
end
