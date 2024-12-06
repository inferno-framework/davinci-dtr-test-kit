module DaVinciDTRTestKit
  module MockAuthorization
    class SimpleTokenEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        request.params[:client_id]
      end

      # Placeholder for a more complete mock token endpoint
      def make_response
        response.body = { access_token: SecureRandom.hex, token_type: 'bearer', expires_in: 3600 }.to_json
        response.status = 200
      end

      def update_result
        results_repo.update_result(result.id, 'pass')
      end
    end
  end
end
