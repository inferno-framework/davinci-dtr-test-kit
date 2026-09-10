require_relative '../../tags'

module DaVinciDTRTestKit
  module MockPayer
    class PayerProxyEndpoint < Inferno::DSL::SuiteEndpoint
      # Override this method to define the endpoint path. Path should lead with '/'
      def payer_path
        raise NotImplementedError, "#{self.class} must implement #payer_path"
      end

      def outgoing_request_tags
        []
      end

      def test_run_identifier
        request.headers['authorization']&.delete_prefix('Bearer ')
      end

      def make_response
        payer_response = forward_and_persist_request

        content_type = payer_response.dig(:headers, 'content-type')

        response.status = payer_response[:status]
        response.headers['Content-Type'] = content_type if content_type.present?
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.body = payer_response[:body]
      end

      def update_result
        results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
      end

      private

      def forward_and_persist_request
        url_input = session_data.load(test_session_id: result.test_session_id, name: 'url')
        payer_url = "#{url_input.chomp('/')}#{payer_path}"
        credentials =
          session_data.load(
            test_session_id: result.test_session_id,
            name: 'backend_services_smart_auth_info',
            type: 'auth_info'
          )

        client = FHIR::Client.new(url_input)
        client.set_bearer_token(credentials.access_token) if credentials&.access_token
        payer_request_body = request.body.string
        payer_request_headers = { 'Content-Type' => 'application/fhir+json' }.merge(client.security_headers)

        # We make the request with the FHIR::Client's underlying client object because the
        # FHIR::Client API requires a FHIR object, and we need to proxy the raw body
        client.client.post(
          payer_url,
          payer_request_body,
          payer_request_headers
        ) do |body, _request, result|
          payer_response = { status: result.code, headers: result.each_header.to_h, body: }
          persist_payer_request(payer_url, payer_request_body, payer_request_headers, payer_response)
          payer_response
        end
      end

      def persist_payer_request(url, body, request_headers, payer_response)
        Inferno::Repositories::Requests.new.create(
          verb: 'POST',
          url:,
          direction: 'outgoing',
          status: payer_response[:status],
          request_body: body,
          response_body: payer_response[:body],
          result_id: result.id,
          test_session_id: result.test_session_id,
          request_headers: request_headers.map { |name, value| { name:, value: } },
          response_headers: payer_response[:headers].map { |name, value| { name:, value: } },
          tags: outgoing_request_tags
        )
      end

      def session_data
        @session_data ||= Inferno::Repositories::SessionData.new
      end
    end
  end
end
