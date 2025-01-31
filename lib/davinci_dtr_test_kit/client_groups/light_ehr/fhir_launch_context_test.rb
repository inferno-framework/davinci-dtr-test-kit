module DaVinciDTRTestKit
  class FhirLaunchContextTest < Inferno::Test
    include SMARTAppLaunch::TokenPayloadValidation

    id :fhir_launch_context_test
    title 'Token exchange response body contains fhirContext'
    description %(
      This test validates that when a DTR is passed a context when launched, that context
      includes fhirContext. This specification can be found in the [Launching DTR](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#launching-dtr)
      section of the DTR IG.
    )

    uses_request :token

    run do
      fhir_context = JSON.parse(request.response_body)
      assert fhir_context['fhirContext'].present?, 'fhirContext not present on the passed launch context'

      validate_fhir_context(fhir_context['fhirContext'])
    end
  end
end
