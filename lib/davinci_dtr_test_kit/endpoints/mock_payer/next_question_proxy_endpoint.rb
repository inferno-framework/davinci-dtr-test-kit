module DaVinciDTRTestKit
  module MockPayer
    class NextQuestionProxyEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        request.headers['authorization']&.delete_prefix('Bearer ')
      end

      def tags
        [NEXT_TAG]
      end

      def make_response
        session_id = result.test_session_id
        session_data = Inferno::Repositories::SessionData.new
        url_input = session_data.load(test_session_id: session_id, name: 'url')
        credentials_input = session_data.load(test_session_id: session_id, name: 'credentials',
                                              type: 'oauth_credentials')

        client = FHIR::Client.new(url_input)
        client.default_json
        client.set_bearer_token(credentials_input.access_token) if credentials_input.access_token
        payer_response = client.send(:post, '/Questionnaire/$next-question', JSON.parse(request.body.string),
                                     { 'Content-Type' => 'application/fhir+json' })

        response.status = 200
        response.format = 'application/fhir+json'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.body = payer_response.response[:body].to_s
      end

      def update_result
        results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
      end
    end
  end
end
