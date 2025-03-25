require 'jwt'
require_relative '../../tags'
require_relative '../../urls'
require_relative '../../descriptions'
require_relative '../../endpoints/mock_udap_smart_server'

module DaVinciDTRTestKit
  class DTRClientPayerSMARTTokenRequestTest < Inferno::Test
    include URLs

    id :dtr_client_payer_smart_token_request_test
    title 'Verify SMART Token Requests'
    description %(
        Check that SMART token requests are conformant.
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

      load_tagged_requests(TOKEN_TAG, SMART_TAG)
      skip_if requests.blank?, 'No SMART token requests made.'

      jti_list = []
      requests.each_with_index do |token_request, index|
        request_params = URI.decode_www_form(token_request.request_body).to_h
        check_request_params(request_params, index)
        check_client_assertion(request_params['client_assertion'], index, jti_list, token_request.url)
      end

      assert messages.none? { |msg|
        msg[:type] == 'error'
      }, 'Invalid token requests detected. See messages for details.'
    end

    def check_request_params(params, index)
      if params['grant_type'] != 'client_credentials'
        add_message('error',
                    "Token request #{index} had an incorrect `grant_type`: expected 'client_credentials', " \
                    "but got '#{params['grant_type']}'")
      end
      if params['client_assertion_type'] != 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        add_message('error',
                    "Token request #{index} had an incorrect `client_assertion_type`: " \
                    "expected 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer', " \
                    "but got '#{params['client_assertion_type']}'")
      end
      return unless params['scope'].blank?

      add_message('error', "Token request #{index} did not include the requested `scope`")
    end

    def check_client_assertion(assertion, index, jti_list, endpoint_aud)
      decoded_token =
        begin
          JWT::EncodedToken.new(assertion)
        rescue StandardError => e
          add_message('error', "Token request #{index} contained an invalid client assertion jwt: #{e}")
          nil
        end

      return unless decoded_token.present?

      check_jwt_header(decoded_token.header, index)
      check_jwt_payload(decoded_token.payload, index, jti_list, endpoint_aud)
      check_jwt_signature(decoded_token, index)
    end

    def check_jwt_header(header, index)
      return unless header['typ'] != 'JWT'

      add_message('error', "client assertion jwt on token request #{index} has an incorrect `typ` header: " \
                           "expected 'JWT', got '#{header['typ']}'")
    end

    def check_jwt_payload(claims, index, jti_list, endpoint_aud)
      if claims['iss'] != client_id
        add_message('error', "client assertion jwt on token request #{index} has an incorrect `iss` claim: " \
                             "expected '#{client_id}', got '#{claims['iss']}'")
      end

      if claims['sub'] != client_id
        add_message('error', "client assertion jwt on token request #{index} has an incorrect `sub` claim: " \
                             "expected '#{client_id}', got '#{claims['sub']}'")
      end

      if claims['aud'] != endpoint_aud
        add_message('error', "client assertion jwt on token request #{index} has an incorrect `aud` claim: " \
                             "expected '#{endpoint_aud}', got '#{claims['aud']}'")
      end

      if claims['exp'].blank?
        add_message('error', "client assertion jwt on token request #{index} is missing the `exp` claim.")
      end

      if claims['jti'].blank?
        add_message('error', "client assertion jwt on token request #{index} is missing the `jti` claim.")
      elsif jti_list.include?(claims['jti'])
        add_message('error', "client assertion jwt on token request #{index} has a `jti` claim that was " \
                             "previouly used: '#{claims['jti']}'.")
      else
        jti_list << claims['jti']
      end
    end

    def check_jwt_signature(encoded_token, index)
      error = MockUdapSmartServer.smart_assertion_signature_verification(encoded_token, smart_jwk_set)

      return unless error.present?

      add_message('error', "Signature validation failed on token request #{index}: #{error}")
    end
  end
end
