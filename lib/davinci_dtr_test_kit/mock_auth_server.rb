# frozen_string_literal: true

require_relative 'urls'

module DaVinciDTRTestKit
  module MockAuthServer
    AUTHORIZED_PRACTITIONER_ID = 'pra1234' # Must exist on the FHIR_REFERENCE_SERVER (env var)

    RSA_PRIVATE_KEY = OpenSSL::PKey::RSA.generate(2048)
    RSA_PUBLIC_KEY = RSA_PRIVATE_KEY.public_key
    SUPPORTED_SCOPES = ['launch', 'patient/*.rs', 'user/*.rs', 'offline_access', 'openid', 'fhirUser'].freeze

    def requests_repo
      @requests_repo ||= Inferno::Repositories::Requests.new
    end

    def auth_server_jwks(_env)
      response_body = {
        keys: [
          {
            kty: 'RSA',
            alg: 'RS256',
            n: Base64.urlsafe_encode64(RSA_PUBLIC_KEY.n.to_s(2), padding: false),
            e: Base64.urlsafe_encode64(RSA_PUBLIC_KEY.e.to_s(2), padding: false),
            use: 'sig'
          }
        ]
      }.to_json

      [200, { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }, [response_body]]
    end

    def ehr_smart_config(env)
      base_url = env_base_url(env, SMART_CONFIG_PATH)
      response_body =
        {
          authorization_endpoint: base_url + EHR_AUTHORIZE_PATH,
          token_endpoint: base_url + EHR_TOKEN_PATH,
          token_endpoint_auth_methods_supported: ['private_key_jwt'],
          token_endpoint_auth_signing_alg_values_supported: ['RS256'],
          grant_types_supported: ['authorization_code'],
          scopes_supported: SUPPORTED_SCOPES,
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

    def ehr_openid_config(env)
      base_url = env_base_url(env, OPENID_CONFIG_PATH)
      response_body = {
        issuer: base_url + FHIR_BASE_PATH,
        authorization_endpoint: base_url + EHR_AUTHORIZE_PATH,
        token_endpoint: base_url + EHR_TOKEN_PATH,
        jwks_uri: base_url + JKWS_PATH,
        response_types_supported: ['id_token'],
        subject_types_supported: ['public'],
        id_token_signing_alg_values_supported: ['RS256']
      }.to_json
      [200, { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }, [response_body]]
    end

    def ehr_authorize(request, _test = nil, _test_result = nil)
      # Authorization requests can bet GET or POST
      params = params_hash(request)
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
      access_token = JWT.encode({ inferno_client_id: client_id }, nil, 'none')
      granted_scopes = SUPPORTED_SCOPES & requested_scopes(test_result.test_session_id)

      response = { access_token:, scope: granted_scopes.join(' '), token_type: 'bearer', expires_in: 3600 }

      if granted_scopes.include?('openid')
        response.merge!(id_token: create_id_token(request, client_id, fhir_user: granted_scopes.include?('fhirUser')))
      end

      fhir_context_input = find_test_input(test_result, 'smart_fhir_context')
      fhir_context_input_value = fhir_context_input['value'] if fhir_context_input
      begin
        fhir_context = JSON.parse(fhir_context_input_value)
      rescue StandardError
        fhir_context = nil
      end
      response.merge!(fhirContext: fhir_context) if fhir_context

      smart_patient_input = find_test_input(test_result, 'smart_patient_id')
      smart_patient_input_value = smart_patient_input['value'] if smart_patient_input.present?
      response.merge!(patient: smart_patient_input_value) if smart_patient_input_value

      request.response_body = response.to_json
      request.response_headers = {
        'Cache-Control' => 'no-store',
        'Pragma' => 'no-cache',
        'Access-Control-Allow-Origin' => '*'
      }
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

    def create_id_token(request, client_id, fhir_user: false)
      # No point in mocking an identity provider, just always use known Practitioner as the authorized user
      suite_base_url = request.url.split(EHR_TOKEN_PATH).first
      id_token_hash = {
        iss: suite_base_url + FHIR_BASE_PATH,
        sub: AUTHORIZED_PRACTITIONER_ID,
        aud: client_id,
        exp: Time.now.to_i + (24 * 60 * 60), # 24 hrs
        iat: Time.now.to_i
      }
      id_token_hash.merge!(fhirUser: "#{suite_base_url}/fhir/Practitioner/#{AUTHORIZED_PRACTITIONER_ID}") if fhir_user

      JWT.encode(id_token_hash, RSA_PRIVATE_KEY, 'RS256')
    end

    def requested_scopes(test_session_id)
      auth_request = requests_repo.tagged_requests(test_session_id, [EHR_AUTHORIZE_TAG]).last
      return [] unless auth_request

      scope_str = params_hash(auth_request)&.dig('scope')
      scope_str ? URI.decode_www_form_component(scope_str).split : []
    end

    def find_test_input(test_result, input_name)
      JSON.parse(test_result.input_json)&.find { |input| input['name'] == input_name }
    end

    def params_hash(request)
      request.verb == 'get' ? request.query_parameters : URI.decode_www_form(request.request_body)&.to_h
    end

    def env_base_url(env, endpoint_path)
      protocol = env['rack.url_scheme']
      host = env['HTTP_HOST']
      path = env['REQUEST_PATH'] || env['PATH_INFO']
      path.gsub!(%r{#{endpoint_path}(/)?}, '')
      "#{protocol}://#{host + path}"
    end
  end
end
