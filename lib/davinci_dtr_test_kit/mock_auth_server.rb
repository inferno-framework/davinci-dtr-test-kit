require_relative 'urls'
require_relative 'fixtures'

module DaVinciDTRTestKit
  module MockAuthServer
    include Fixtures

    def ehr_smart_config(env)
      protocol = env['rack.url_scheme']
      host = env['HTTP_HOST']
      path = env['REQUEST_PATH'] || env['PATH_INFO']
      path.gsub!(%r{#{SMART_CONFIG_PATH}(/)?}, '')
      base_url = "#{protocol}://#{host + path}"
      response_body =
        {
          authorization_endpoint: base_url + EHR_AUTHORIZE_PATH,
          token_endpoint: base_url + EHR_TOKEN_PATH,
          token_endpoint_auth_methods_supported: ['private_key_jwt'],
          token_endpoint_auth_signing_alg_values_supported: ['RS256'],
          grant_types_supported: ['authorization_code'],
          scopes_supported: ['launch', 'patient/*.rs', 'user/*.rs', 'offline_access'],
          response_types_supported: ['code'],
          code_challenge_methods_supported: ['S256'],
          capabilities: [
            'launch-ehr',
            'permission-patient',
            'permission-user',
            'client-confidential-asymmetric'
          ]
        }.to_json

      [200, { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }, [response_body]]
    end

    def ehr_authorize(request, _test = nil, _test_result = nil)
      # Authorization requests can bet GET or POST
      params = request.verb == 'get' ? request.query_parameters : URI.decode_www_form(request.request_body)&.to_h
      if params['redirect_uri'].present?
        redirect_uri = "#{params['redirect_uri']}?" \
                       "code=#{SecureRandom.hex}&" \
                       "state=#{params['state']}"
        request.status = 302
        request.response_headers = { 'Location' => redirect_uri }
      else
        request.status = 400
        request.response_headers = { 'Content-Type': 'application/json' }
        request.response_body = FHIR::OperationOutcome.new(
          issue: FHIR::OperationOutcome::Issue.new(severity: 'fatal', code: 'required',
                                                   details: FHIR::CodeableConcept.new(
                                                     text: 'No redirect_uri provided'
                                                   ))
        ).to_json
      end
    end

    def ehr_token_response(request, _test = nil, test_result = nil)
      client_id = extract_client_id_from_client_assertion(request)
      token = JWT.encode({ client_id: }, nil, 'none')
      smart_app_launch = JSON.parse(test_result.input_json).find { |input| input['name'] == 'smart_app_launch' }
      response = { access_token: token, token_type: 'bearer', expires_in: 300 }
      if smart_app_launch.present?
        # When Test Kit supports more than one questionnaire with SMART Launch, this will have to become more dynamic
        response.merge!({ patient: 'pat015', fhirContext: [{ reference: 'Coverage/cov015' },
                                                           { reference: 'DeviceRequest/devreqe0470' }] })
      end
      request.response_body = response.to_json
      request.response_headers = { 'Access-Control-Allow-Origin' => '*' }
      request.status = 200
    end

    def payer_token_response(request, _test = nil, _test_result = nil)
      # Placeholder for a more complete mock token endpoint
      request.response_body = { access_token: SecureRandom.hex, token_type: 'bearer', expires_in: 300 }.to_json
      request.status = 200
    end

    def extract_client_id_from_form_params(request)
      URI.decode_www_form(request.request_body).to_h['client_id']
    end

    def extract_client_id_from_client_assertion(request)
      encoded_jwt = URI.decode_www_form(request.request_body).to_h['client_assertion']
      jwt_payload = JWT.decode(encoded_jwt, nil, false)&.first # skip signature verification
      jwt_payload['iss'] || jwt_payload['sub']
    end

    def extract_client_id_from_query_params(request)
      request.query_parameters['client_id']
    end

    def extract_client_id_from_bearer_token(request)
      token = extract_bearer_token(request)
      JWT.decode(token, nil, false)&.first&.dig('client_id')
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