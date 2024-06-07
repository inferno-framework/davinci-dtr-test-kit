module DaVinciDTRTestKit
  class TokentRequestTest < Inferno::Test
    id :token_validation
    title 'Client token request is valid'
    description 'Inferno will verify that an access token was successfully returned to the client under test.'
    output :access_token

    run do
      skip_if request.blank?, 'No token requests were received'
      output access_token: JSON.parse(request.response_body)['access_token']
    end
  end
end
