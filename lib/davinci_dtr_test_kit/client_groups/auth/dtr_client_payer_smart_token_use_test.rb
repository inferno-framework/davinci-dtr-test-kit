require_relative '../../tags'
require_relative '../../urls'
require_relative '../../descriptions'
require_relative '../../endpoints/mock_udap_smart_server'

module DaVinciDTRTestKit
  class DTRClientPayerSMARTTokenUseTest < Inferno::Test
    include URLs

    id :dtr_client_payer_smart_token_use_test
    title 'Verify SMART Token Use'
    description %(
        Check that a SMART token returne to the client was used for request
        authentication.
      )

    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED
    input :smart_jwk_set,
          title: 'JSON Web Key Set (JWKS)',
          type: 'textarea',
          optional: true,
          locked: true,
          description: INPUT_JWK_SET_LOCKED

    run do
      omit_if smart_jwk_set.blank?,
              'SMART Backend Services authentication not demonstrated as a part of this test session.'

      token_requests = load_tagged_requests(TOKEN_TAG, SMART_TAG)
      prior_auth_requests = load_tagged_requests(QUESTIONNAIRE_PACKAGE_TAG) + load_tagged_requests(CLIENT_NEXT_TAG)

      skip_if token_requests.blank?, 'No token requests made.'
      skip_if prior_auth_requests.blank?, 'No prior authorization requests made.'

      used_tokens = prior_auth_requests.map do |authed_request|
        authed_request.request_headers.find do |header|
          header.name.downcase == 'authorization'
        end&.value&.delete_prefix('Bearer ')
      end.compact

      request_with_used_token = token_requests.find do |token_request|
        used_tokens.include?(JSON.parse(token_request.response_body)&.dig('access_token'))
      end

      assert request_with_used_token.present?, 'Returned tokens never used in any requests.'
    end
  end
end
