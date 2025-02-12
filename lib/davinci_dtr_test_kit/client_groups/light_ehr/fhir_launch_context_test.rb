module DaVinciDTRTestKit
  class FhirLaunchContextTest < Inferno::Test
    include SMARTAppLaunch::TokenPayloadValidation

    id :fhir_launch_context_test
    title 'Token exchange response body contains fhirContext'
    description %(
      This test validates that when the light EHR launches a DTR SMART App, the launch context
      includes a `fhirContext`. See the [Launching DTR](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#launching-dtr)
      section of the DTR IG for details.
    )
    optional

    uses_request :token

    run do
      token_response_params = JSON.parse(request.response_body)
      assert token_response_params['fhirContext'].present?, 'fhirContext not present on the passed launch context'

      validate_fhir_context(token_response_params['fhirContext'])
    end
  end
end
