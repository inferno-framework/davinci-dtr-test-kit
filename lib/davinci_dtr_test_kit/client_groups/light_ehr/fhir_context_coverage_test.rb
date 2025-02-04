module DaVinciDTRTestKit
  class FhirContextCoverageTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    id :fhir_context_coverage_test
    title 'FHIR Context Coverage Test'
    description %(
      This test validates that when the light EHR launches a DTR SMART App, the launch context includes
      a fhirContext with one active Coverage resource.
      This specification can be found in the [Launching DTR](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#launching-dtr)
      section of the DTR IG.
    )
    optional

    uses_request :token

    fhir_client do
      url :url
      bearer_token JSON.parse(request.response_body)['access_token']
    end

    run do
      token_response_params = JSON.parse(request.response_body)

      assert token_response_params['fhirContext'].present?, 'fhirContext not present on the passed launch context'

      coverage = token_response_params['fhirContext'].find { |c| c.split('/')[0] == 'Coverage' }
      assert coverage.present?, 'Coverage resource not present on fhirContext'

      coverage_array = [coverage.split('/')[1]]
      assert coverage_array.present?, 'Coverage resource not present on fhirContext in proper format'

      perform_read_test(coverage_array, 'Coverage')
    end
  end
end
