require_relative '../urls'

module DaVinciDTRTestKit
  class TokenRequestTest < Inferno::Test
    include URLs

    id :token_request
    title 'Client makes token request'
    description %(
      Inferno will wait for the client to make a token request.
    )
    input :client_id, default: SecureRandom.hex

    run do
      wait(
        identifier: client_id,
        message: %(
          Submit your token request to

          `#{payer_token_url}`
        )
      )
    end
  end
end
