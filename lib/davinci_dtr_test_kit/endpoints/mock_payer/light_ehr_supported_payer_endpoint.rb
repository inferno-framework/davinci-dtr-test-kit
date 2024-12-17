require_relative '../mock_payer'

module DaVinciDTRTestKit
  module Endpoints
    module MockPayer
      class LightEHRSupportedPayerEndpoint < Inferno::DSL::SuiteEndpoint
        include DaVinciDTRTestKit::MockPayer

        def make_response
          puts "Request method: #{request.request_method}"
          if request.headers['Accept'] != 'application/json'
            response.status = 406
            response.body = { error: 'Not Acceptable', message: 'Accept header must be application/json' }.to_json
            response.headers['Content-Type'] = 'application/json'
            return
          end

          response.status = 200
          response.body = {
            payers: [
              { id: 'payer1', name: 'Payer One' },
              { id: 'payer2', name: 'Payer Two' }
            ]
          }.to_json
          response.headers['Content-Type'] = 'application/json'
        end

        def tags
          ['supported_payers']
        end

        def name
          'light_ehr_supported_payer_endpoint'
        end
      end
    end
  end
end
