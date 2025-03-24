require 'jwt'
require 'faraday'
require 'time'
require 'udap_security_test_kit'
require_relative '../urls'
require_relative '../tags'

module DaVinciDTRTestKit
  module MockUdapSmartServer
    include Inferno::DSL::HTTPClient
    SUPPORTED_SCOPES = ['openid', 'system/*.read', 'user/*.read', 'patient/*.read'].freeze

    module_function

    def smart_server_metadata(env)
      base_url = env_base_url(env, SMART_DISCOVERY_PATH)
      response_body = {
        token_endpoint_auth_signing_alg_values_supported: ['RS384', 'ES384'],
        capabilities: ['client-confidential-asymmetric'],
        code_challenge_methods_supported: ['S256'],
        token_endpoint_auth_methods_supported: ['private_key_jwt'],
        issuer: base_url + FHIR_BASE_PATH,
        grant_types_supported: ['client_credentials'],
        scopes_supported: SUPPORTED_SCOPES,
        token_endpoint: base_url + TOKEN_PATH
      }.to_json

      [200, { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }, [response_body]]
    end

    def udap_server_metadata(env)
      base_url = env_base_url(env, UDAP_DISCOVERY_PATH)
      response_body = {
        udap_versions_supported: ['1'],
        udap_profiles_supported: ['udap_dcr', 'udap_authn', 'udap_authz'],
        udap_authorization_extensions_supported: ['hl7-b2b'],
        udap_authorization_extensions_required: [],
        udap_certifications_supported: [],
        udap_certifications_required: [],
        grant_types_supported: ['client_credentials'],
        scopes_supported: SUPPORTED_SCOPES,
        token_endpoint: base_url + TOKEN_PATH,
        token_endpoint_auth_methods_supported: ['private_key_jwt'],
        token_endpoint_auth_signing_alg_values_supported: ['RS384', 'ES384'],
        registration_endpoint: base_url + REGISTRATION_PATH,
        registration_endpoint_jwt_signing_alg_values_supported: ['RS384', 'ES384'],
        signed_metadata: udap_signed_metadata_jwt(base_url)
      }.to_json

      [200, { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }, [response_body]]
    end

    def udap_signed_metadata_jwt(base_url)
      jwt_claim_hash = {
        iss: base_url + FHIR_BASE_PATH,
        sub: base_url + FHIR_BASE_PATH,
        exp: 5.minutes.from_now.to_i,
        iat: Time.now.to_i,
        jti: SecureRandom.hex(32),
        token_endpoint: base_url + TOKEN_PATH,
        registration_endpoint: base_url + REGISTRATION_PATH
      }.compact

      UDAPSecurityTestKit::UDAPJWTBuilder.encode_jwt_with_x5c_header(
        jwt_claim_hash,
        test_kit_private_key,
        'RS256',
        [test_kit_cert]
      )
    end

    def root_ca_cert
      File.read(
        ENV.fetch('DTR_ROOT_CA_CERT_FILE',
                  File.join(__dir__, '..',
                            'certs', 'infernoCA.pem'))
      )
    end

    def root_ca_private_key
      File.read(
        ENV.fetch('DTR_ROOT_CA_PRIVATE_KEY_FILE',
                  File.join(__dir__, '..',
                            'certs', 'infernoCA.key'))
      )
    end

    def test_kit_cert
      File.read(
        ENV.fetch('DTR_TEST_KIT_CERT_FILE',
                  File.join(__dir__, '..',
                            'certs', 'TestKit.pem'))
      )
    end

    def test_kit_private_key
      File.read(
        ENV.fetch('DTR_TEST_KIT_PRIVATE_KEY_FILE',
                  File.join(__dir__, '..',
                            'certs', 'TestKitPrivateKey.key'))
      )
    end

    def env_base_url(env, endpoint_path)
      protocol = env['rack.url_scheme']
      host = env['HTTP_HOST']
      path = env['REQUEST_PATH'] || env['PATH_INFO']
      path.gsub!(%r{#{endpoint_path}(/)?}, '')
      "#{protocol}://#{host + path}"
    end

    def parsed_request_body(request)
      JSON.parse(request.request_body)
    rescue JSON::ParserError
      nil
    end

    def parsed_io_body(request)
      parsed_body = begin
        JSON.parse(request.body.read)
      rescue JSON::ParserError
        nil
      end
      request.body.rewind

      parsed_body
    end

    def jwt_claims(encoded_jwt)
      JWT.decode(encoded_jwt, nil, false)[0]
    end

    def client_uri_to_client_id(client_uri)
      Base64.strict_encode64(client_uri)
    end

    def client_id_to_client_uri(client_id)
      Base64.decode64(client_id)
    end

    def client_id_to_token(client_id, exp_min)
      token_structure = {
        client_id:,
        expiration: exp_min.minutes.from_now.to_i,
        nonce: SecureRandom.hex(8)
      }.to_json

      Base64.strict_encode64(token_structure)
    end

    def decode_token(token)
      JSON.parse(Base64.decode64(token))
    rescue JSON::ParserError
      nil
    end

    def token_to_client_id(token)
      decode_token(token)&.dig('client_id')
    end

    def jwk_set(jku, warning_messages = [])
      jwk_set = JWT::JWK::Set.new

      if jku.blank?
        warning_messages << 'No key set input.'
        return jwk_set
      end

      jwk_body = # try as raw jwk set
        begin
          JSON.parse(jku)
        rescue JSON::ParserError
          nil
        end

      if jwk_body.blank?
        retrieved = Faraday.get(jku) # try as url pointing to a jwk set
        jwk_body =
          begin
            JSON.parse(retrieved.body)
          rescue JSON::ParserError
            warning_messages << "Failed to fetch valid json from jwks uri #{jwk_set}."
            nil
          end
      else
        warning_messages << 'Providing the JWK Set directly is strongly discouraged.'
      end

      return jwk_set if jwk_body.blank?

      jwk_body['keys']&.each_with_index do |key_hash, index|
        parsed_key =
          begin
            JWT::JWK.new(key_hash)
          rescue JWT::JWKError => e
            id = key_hash['kid'] | index
            warning_messages << "Key #{id} invalid: #{e}"
            nil
          end
        jwk_set << parsed_key unless parsed_key.blank?
      end

      jwk_set
    end

    def request_has_expired_token?(request)
      return false if request.params[:session_path].present?

      token = request.headers['authorization']&.delete_prefix('Bearer ')
      decoded_token = decode_token(token)
      return false unless decoded_token&.dig('expiration').present?

      decoded_token['expiration'] < Time.now.to_i
    end

    def update_response_for_expired_token(response)
      response.status = 401
      response.format = :json
      response.body = FHIR::OperationOutcome.new(
        issue: FHIR::OperationOutcome::Issue.new(severity: 'fatal', code: 'expired',
                                                 details: FHIR::CodeableConcept.new(text: 'Bearer token has expired'))
      ).to_json
    end

    def smart_assertion_signature_verification(token, key_set_input)
      encoded_token = nil
      if token.is_a?(JWT::EncodedToken)
        encoded_token = token
      else
        begin
          encoded_token = JWT::EncodedToken.new(token)
        rescue StandardError => e
          return "invalid token structure: #{e}"
        end
      end
      return 'invalid token' unless encoded_token.present?
      return 'missing `alg` header' if encoded_token.header['alg'].blank?
      return 'missing `kid` header' if encoded_token.header['kid'].blank?

      jwk = identify_smart_signing_key(encoded_token.header['kid'], encoded_token.header['jku'], key_set_input)
      return "no key found with `kid` '#{encoded_token.header['kid']}'" if jwk.blank?

      begin
        encoded_token.verify_signature!(algorithm: encoded_token.header['alg'], key: jwk.verify_key)
      rescue StandardError => e
        return e
      end

      nil
    end

    def identify_smart_signing_key(kid, jku, key_set_input)
      key_set = jku.present? ? jku : key_set_input
      parsed_key_set = jwk_set(key_set)
      parsed_key_set&.find { |key| key.kid == kid }
    end

    def udap_assertion_signature_verification(assertion_jwt, registration_jwt = nil)
      _assertion_body, assertion_header = JWT.decode(assertion_jwt, nil, false)
      return 'missing `x5c` header' if assertion_header['x5c'].blank?
      return 'missing `alg` header' if assertion_header['alg'].blank?

      leaf_cert_der = Base64.decode64(assertion_header['x5c'].first)
      leaf_cert = OpenSSL::X509::Certificate.new(leaf_cert_der)
      signature_validation_result = UDAPSecurityTestKit::UDAPJWTValidator.validate_signature(
        assertion_jwt,
        assertion_header['alg'],
        leaf_cert
      )
      return signature_validation_result[:error_message] unless signature_validation_result[:success]
      return unless registration_jwt

      # check trust
      _registration_body, registration_header = JWT.decode(registration_jwt, nil, false)
      unless assertion_header['x5c'].first == registration_header['x5c'].first
        return 'signing cert does not match registration cert'
      end

      nil
    end

    def udap_registration_software_statement(test_session_id)
      registration_requests =
        Inferno::Repositories::Requests.new.tagged_requests(test_session_id, [UDAP_TAG, REGISTRATION_TAG])
      return unless registration_requests.present?

      parsed_body = MockUdapSmartServer.parsed_request_body(registration_requests.last)
      parsed_body&.dig('software_statement')
    end

    def update_response_for_invalid_assertion(response, error_message)
      response.status = 401
      response.format = :json
      response.body = { error: 'invalid_client', error_description: error_message }.to_json
    end
  end
end
