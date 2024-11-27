require_relative '../../urls'
require_relative 'constants'

module DaVinciDTRTestKit
  module MockAuthorization
    module_function

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

    private

    def env_base_url(env, endpoint_path)
      protocol = env['rack.url_scheme']
      host = env['HTTP_HOST']
      path = env['REQUEST_PATH'] || env['PATH_INFO']
      path.gsub!(%r{#{endpoint_path}(/)?}, '')
      "#{protocol}://#{host + path}"
    end
  end
end
