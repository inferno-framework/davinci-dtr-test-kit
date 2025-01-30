require_relative '../../tags'

module DaVinciDTRTestKit
  class LightEHRSupportedPayerEndpoint < Inferno::DSL::SuiteEndpoint
    def name
      'light_ehr_supported_payer_endpoint'
    end

    def test_run_identifier
      request.params[:tester_url_id]
    end

    def tags
      [SUPPORTED_PAYER_TAG]
    end

    def make_response
      puts "Request method: #{request.request_method}"

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
      results_repo.update_result(result.id, 'pass')
    end
  end
end
