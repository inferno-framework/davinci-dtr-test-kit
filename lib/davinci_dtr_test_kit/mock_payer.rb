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

    def payer_adaptive_questionnaire_response(request, _test = nil, _test_result = nil)
      endpoint_input = JSON.parse(_test_result.input_json).find { |input| input['name'] == 'adaptive_endpoint' }
      url_input = JSON.parse(_test_result.input_json).find { |input| input['name'] == 'url' }
      client = FHIR::Client.new(url_input['value'])
      client.default_json
      endpoint = endpoint_input['value'].nil? ? '/Questionnaire/$questionnaire-package' : endpoint_input['value']
      payer_response = client.send(:post, endpoint, JSON.parse(request.request_body),
                                   { 'Content-Type' => 'application/json' })

      request.status = 200
      request.response_headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': 'http://localhost:3005' }
      request.response_body = payer_response.response[:body].to_s
    end

    def questionnaire_next_response(request, _test = nil, _test_result = nil)
      url_endpoint = JSON.parse(_test_result.input_json).find { |input| input['name'] == 'url' }
      client = FHIR::Client.new(url_endpoint['value'])
      client.default_json
      payer_response = client.send(:post, '/Questionnaire/$next-question', JSON.parse(request.request_body),
                                   { 'Content-Type' => 'application/json' })

      request.status = 200
      request.response_headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': 'http://localhost:3005' }

      request.response_body = payer_response.response[:body]
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

    def test_resumes?(_test)
      false
    end
  end
end
