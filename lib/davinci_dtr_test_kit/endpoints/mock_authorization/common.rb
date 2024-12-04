module DaVinciDTRTestKit
  module MockAuthorization
    RSA_PRIVATE_KEY = OpenSSL::PKey::RSA.generate(2048)
    RSA_PUBLIC_KEY = RSA_PRIVATE_KEY.public_key
    SUPPORTED_SCOPES = ['launch', 'patient/*.rs', 'user/*.rs', 'offline_access', 'openid', 'fhirUser'].freeze

    module_function

    def extract_client_id_from_bearer_token(request)
      token = request.headers['authorization']&.delete_prefix('Bearer ')
      jwt =
        begin
          JWT.decode(token, nil, false)
        rescue StandardError
          nil
        end
      jwt&.first&.dig('inferno_client_id')
    end
  end
end
