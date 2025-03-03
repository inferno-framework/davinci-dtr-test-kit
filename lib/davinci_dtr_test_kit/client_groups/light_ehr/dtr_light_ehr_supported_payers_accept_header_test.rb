require_relative '../../urls'
require_relative '../../tags'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayersAcceptHeaderTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_sp_accept_header
    title 'Client uses the required Accept HTTP header value'
    description %(
      This test verifies that the request to the supported payers endpoint
      includes an `Accept` HTTP header set to `application/json`.
    )

    run do
      load_tagged_requests(SUPPORTED_PAYER_TAG)
      accept_header = request.request_headers.find { |header| header.name.downcase == 'accept' }

      assert accept_header.present?, 'Accept header must be provided'
      assert accept_header.value == 'application/json', "Invalid Accept header: Expected 'application/json'
                                      but received '#{accept_header.value}'"
      pass 'Accept header is correctly set to application/json'
    end
  end
end
