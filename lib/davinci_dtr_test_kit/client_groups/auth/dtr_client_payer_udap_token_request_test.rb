require_relative '../../tags'
require_relative '../../urls'
require_relative '../../descriptions'
require_relative '../../endpoints/mock_udap_smart_server'

module DaVinciDTRTestKit
  class DTRClientPayerUDAPTokenRequestTest < Inferno::Test
    include URLs

    id :dtr_client_payer_udap_token_request_test
    title 'Verify UDAP Token Requests'
    description %(
        Check that UDAP token requests are conformant.
      )

    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          locked: true,
          description: INPUT_CLIENT_ID_LOCKED

    run do
      load_tagged_requests(REGISTRATION_TAG, UDAP_TAG)
      omit_if requests.blank?, 'UDAP Authentication not demonstrated as a part of this test session.'
      registration_request = requests.last

      requests.clear
      load_tagged_requests(TOKEN_TAG, UDAP_TAG)

      skip_if requests.blank?, 'No UDAP token requests made.'

      jti_list = []
      requests.each_with_index do |token_request, index|
        request_params = URI.decode_www_form(token_request.request_body).to_h
        check_request_params(request_params, index)
        check_client_assertion(request_params['client_assertion'], index, jti_list, registration_request,
                               token_request.url)
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
      return unless params['udap'].to_s != '1'

      add_message('error',
                  "Token request #{index} had an incorrect `udap`: " \
                  "expected '1', " \
                  "but got '#{params['udap']}'")
    end

    def check_client_assertion(assertion, index, jti_list, registration_request, endpoint_aud)
      decoded_token =
        begin
          JWT::EncodedToken.new(assertion)
        rescue StandardError => e
          add_message('error', "Token request #{index} contained an invalid client assertion jwt: #{e}")
          nil
        end

      return unless decoded_token.present?

      # header checked with signature
      check_jwt_payload(decoded_token.payload, index, jti_list, endpoint_aud)
      check_jwt_signature(decoded_token, registration_request, index)
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

      check_b2b_auth_extension(claim.dig('extension', 'hl7-b2b'), index)
    end

    def check_b2b_auth_extension(b2b_auth, index)
      if b2b_auth.blank?
        add_message('error', "client assertion jwt on token request #{index} missing the `hl7-b2b` extension.")
        return
      end

      if b2b_auth['version'].blank?
        add_message('error', "the `hl7-b2b` extension on client assertion jwt on token request #{index} is missing " \
                             'the required `version` key.')
      elsif b2b_auth['version'].to_s != '1'
        add_message('error', "the `hl7-b2b` extension on client assertion jwt on token request #{index} has an " \
                             "incorrect `version` value: expected `1`, got #{b2b_auth['version']}.")
      end

      if b2b_auth['organization_id'].blank?
        add_message('error', "the `hl7-b2b` extension on client assertion jwt on token request #{index} is missing " \
                             'the required `organization_id` key.')
      end

      if b2b_auth['purpose_of_use'].blank?
        add_message('error', "the `hl7-b2b` extension on client assertion jwt on token request #{index} is missing " \
                             'the required `purpose_of_use` key.')
      end

      nil
    end
  end
end
