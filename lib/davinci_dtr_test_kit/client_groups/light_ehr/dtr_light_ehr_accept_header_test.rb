require_relative '../../urls'
require_relative '../../tags'

module DaVinciDTRTestKit
  class DTRLightEHRAcceptHeaderTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_accept_header
    title 'Checks for a valid Accept header at the supported payer endpoint'
    description %(
      This test verifies that the request to the supported payer endpoint
      includes an Accept header set to application/json.
    )

    run do
      load_tagged_requests(SUPPORTED_PAYER_TAG)
      accept_header = request.request_headers.find { |header| header.name.downcase == 'accept' }

      assert accept_header.present?, 'Accept header must be provided'
      assert accept_header.value == 'application/json', 'Header value must be application/json'

      pass 'Accept header is correctly set to application/json'
    end
  end
end
