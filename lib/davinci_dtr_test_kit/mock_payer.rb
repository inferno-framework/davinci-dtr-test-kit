require_relative 'fixtures'

module DaVinciDTRTestKit
  module MockPayer
    include Fixtures

    def token_response(request, _test = nil, _test_result = nil)
      # Placeholder for a more complete mock token endpoint
      request.response_body = { access_token: SecureRandom.hex, token_type: 'bearer', expires_in: 300 }.to_json
      request.status = 200
    end

    def questionnaire_package_response(request, _test = nil, _test_result = nil)
      request.status = 200
      request.response_headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': 'http://localhost:3005' }
      request.response_body = questionnaire_package.to_json
    end

    def questionnaire_response_response(request, _test = nil, _test_result = nil)
      request.status = 201
      request.response_headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': 'http://localhost:3005' }
      request.response_body = request.request_body
    end

    def extract_client_id(request)
      URI.decode_www_form(request.request_body).to_h['client_id']
    end

    # Header expected to be a bearer token of the form "Bearer: <token>"
    def extract_bearer_token(request)
      request.request_header('Authorization')&.value&.split&.last
    end

    def extract_token_from_query_params(request)
      request.query_parameters['token']
    end
  end
end
