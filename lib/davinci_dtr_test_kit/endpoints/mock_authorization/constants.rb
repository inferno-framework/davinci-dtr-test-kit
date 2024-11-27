module DaVinciDTRTestKit
  module MockAuthorization
    RSA_PRIVATE_KEY = OpenSSL::PKey::RSA.generate(2048)
    RSA_PUBLIC_KEY = RSA_PRIVATE_KEY.public_key
    SUPPORTED_SCOPES = ['launch', 'patient/*.rs', 'user/*.rs', 'offline_access', 'openid', 'fhirUser'].freeze
  end
end
