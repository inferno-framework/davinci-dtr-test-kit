require_relative 'urls'

module DaVinciDTRTestKit
  module MockAuthServer
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
            'client-public',
            'client-confidential-symmetric',
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
      client_id = extract_client_id_from_token_request(request)
      token = JWT.encode({ inferno_client_id: client_id }, nil, 'none')
      response = { access_token: token, token_type: 'bearer', expires_in: 3600 }

      fhir_context_input = find_test_input(test_result, 'smart_fhir_context')
      fhir_context_input_value = fhir_context_input['value'] if fhir_context_input
      begin
        fhir_context = JSON.parse(fhir_context_input_value)
      rescue StandardError
        fhir_context = nil
      end
      response.merge!({ fhirContext: fhir_context }) if fhir_context

      smart_patient_input = find_test_input(test_result, 'smart_patient_id')
      smart_patient_input_value = smart_patient_input['value'] if smart_patient_input.present?
      response.merge!({ patient: smart_patient_input_value }) if smart_patient_input_value

      request.response_body = response.to_json
      request.response_headers = { 'Access-Control-Allow-Origin' => '*' }
      request.status = 200
    end

    def payer_token_response(request, _test = nil, _test_result = nil)
      # Placeholder for a more complete mock token endpoint
      request.response_body = { access_token: SecureRandom.hex, token_type: 'bearer', expires_in: 3600 }.to_json
      request.status = 200
    end

    def extract_client_id_from_token_request(request)
      # Public client || confidential client asymmetric || confidential client symmetric
      extract_client_id_from_form_params(request) ||
        extract_client_id_from_client_assertion(request) ||
        extract_client_id_from_basic_auth(request)
    end

    def extract_client_id_from_form_params(request)
      URI.decode_www_form(request.request_body).to_h['client_id']
    end

    def extract_client_id_from_client_assertion(request)
      encoded_jwt = URI.decode_www_form(request.request_body).to_h['client_assertion']
      return unless encoded_jwt.present?

      jwt_payload =
        begin
          JWT.decode(encoded_jwt, nil, false)&.first # skip signature verification
        rescue StandardError
          nil
        end

      jwt_payload['iss'] || jwt_payload['sub'] if jwt_payload.present?
    end

    def extract_client_id_from_basic_auth(request)
      encoded_credentials = request.request_header('Authorization')&.value&.split&.last
      return unless encoded_credentials.present?

      decoded_credentials = Base64.decode64(encoded_credentials)
      decoded_credentials&.split(':')&.first
    end

    def extract_client_id_from_query_params(request)
      request.query_parameters['client_id']
    end

    def extract_client_id_from_bearer_token(request)
      token = extract_bearer_token(request)
      jwt =
        begin
          JWT.decode(token, nil, false)
        rescue StandardError
          nil
        end
      jwt&.first&.dig('inferno_client_id')
    end

    # Header expected to be a bearer token of the form "Bearer: <token>"
    def extract_bearer_token(request)
      request.request_header('Authorization')&.value&.split&.last
    end

    def extract_token_from_query_params(request)
      request.query_parameters['token']
    end

    def find_test_input(test_result, input_name)
      JSON.parse(test_result.input_json)&.find { |input| input['name'] == input_name }
    end
  end
end
