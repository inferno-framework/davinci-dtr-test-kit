module DaVinciDTRTestKit
  module MockPayer
    class QuestionnairePackageProxyEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        request.headers['authorization']&.delete_prefix('Bearer ')
      end

      def tags
        [QUESTIONNAIRE_TAG]
      end

      def make_response
        session_id = result.test_session_id
        session_data = Inferno::Repositories::SessionData.new
        endpoint_input = session_data.load(test_session_id: session_id, name: 'custom_endpoint')
        url_input = session_data.load(test_session_id: session_id, name: 'url')
        credentials_input = session_data.load(test_session_id: session_id, name: 'credentials',
                                              type: 'oauth_credentials')

        client = FHIR::Client.new(url_input)
        client.default_json
        client.set_bearer_token(credentials_input.access_token) if credentials_input.access_token
        endpoint = endpoint_input.nil? ? '/Questionnaire/$questionnaire-package' : endpoint_input
        payer_response = client.send(:post, endpoint, JSON.parse(request.body.string),
                                     { 'Content-Type' => 'application/json' })

        response.status = 200
        response.format = :json
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.body = payer_response.response[:body].to_s
      end

      def update_result
        results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
      end
    end
  end
end
