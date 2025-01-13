module DaVinciDTRTestKit
  class FhirLaunchContext < Inferno::Test
    include SMARTAppLaunch::TokenPayloadValidation

    id :fhir_launch_context
    title 'Token output contains fhirContext'

    uses_request :token

    run do
      fhir_context = JSON.parse(request.response_body)
      assert fhir_context['fhirContext'].present?

      validate_fhir_context(fhir_context['fhirContext'])
    end
  end
end
