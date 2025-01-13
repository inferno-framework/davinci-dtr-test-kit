require_relative 'read_test'

module DaVinciDTRTestKit
  class CoverageContextReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    id :coverage_context_read
    title 'Coverage read'

    uses_request :token

    fhir_client do
      url :url
      bearer_token JSON.parse(request.response_body)['access_token']
    end

    run do
      fhir_context = JSON.parse(request.response_body)
      assert fhir_context['fhirContext'].present?

      coverage = fhir_context['fhirContext'].find { |c| c.split('/')[0] = 'Coverage' }
      assert coverage.present?

      coverage_array = [coverage.split('/')[1]]
      assert coverage_array.present?

      perform_read_test(coverage_array, 'Coverage')
    end
  end
end
