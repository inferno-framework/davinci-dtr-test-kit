# frozen_string_literal: true

require_relative '../../urls'
require_relative '../../tags'
require_relative '../mock_udap_smart_server'

module DaVinciDTRTestKit
  module MockUdapSmartServer
    class TokenEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        client_id_from_client_assertion(request.params[:client_assertion])
      end

      def make_response
        assertion = request.params[:client_assertion]
        client_id = client_id_from_client_assertion(assertion)

        signature_error =
          if request.params[:udap].present?
            software_statement = MockUdapSmartServer.udap_registration_software_statement(test_run.test_session_id)
            MockUdapSmartServer.udap_assertion_signature_verification(assertion, software_statement)
          else
            key_set_input = JSON.parse(result.input_json)&.find do |i|
              i['name'] == 'smart_jwk_set'
            end&.dig('value')
            MockUdapSmartServer.smart_assertion_signature_verification(assertion, key_set_input)
          end
        if signature_error.present?
          MockUdapSmartServer.update_response_for_invalid_assertion(response, signature_error)
          return
        end

        exp_min = 60
        response_body = {
          access_token: MockUdapSmartServer.client_id_to_token(client_id, exp_min),
          token_type: 'Bearer',
          expires_in: 60 * exp_min
        }
        if !request.params[:udap].present? && request.params[:scope].present?
          response_body['scope'] = request.params[:scope]
        end

        response.body = response_body.to_json
        response.headers['Cache-Control'] = 'no-store'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.content_type = 'application/json'
        response.status = 200
      end

      def update_result
        nil # never update for now
      end

      def tags
        type_tag = request.params[:udap].present? ? UDAP_TAG : SMART_TAG
        [TOKEN_TAG, type_tag]
      end

      private

      def client_id_from_client_assertion(client_assertion_jwt)
        return unless client_assertion_jwt.present?

        MockUdapSmartServer.jwt_claims(client_assertion_jwt)&.dig('iss')
      end
    end
  end
end
