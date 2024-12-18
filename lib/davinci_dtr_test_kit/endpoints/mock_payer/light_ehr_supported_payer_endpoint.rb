require_relative '../mock_payer'
require_relative '../../tags'

module DaVinciDTRTestKit
  module MockPayer
    class LightEHRSupportedPayerEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer

      def name
        'light_ehr_supported_payer_endpoint'
      end

      def test_run_identifier
        request.headers['authorization']&.delete_prefix('Bearer ')
      end

      def tags
        [SUPPORTED_PAYER_TAG]
      end

      def make_response
        puts "Request method: #{request.request_method}"
        if request.headers['Accept'] != 'application/json'
          response.status = 406
          response.headers['Content-Type'] = 'application/json'
          response.body = { error: 'Not Acceptable', message: 'Accept header must be application/json' }.to_json
          return
        end

        response.status = 200
        response.headers['Content-Type'] = 'application/json'
        response.body = {
          payers: [
            { id: 'payer1', name: 'Payer One' },
            { id: 'payer2', name: 'Payer Two' }
          ]
        }.to_json
      end

      def update_result
        results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
      end
    end
  end
end
