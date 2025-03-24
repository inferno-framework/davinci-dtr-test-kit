# frozen_string_literal: true

require_relative '../../urls'
require_relative '../../tags'
require_relative '../mock_udap_smart_server'

module DaVinciDTRTestKit
  module MockUdapSmartServer
    class RegistrationEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        MockUdapSmartServer.client_uri_to_client_id(
          client_uri_from_registration_payload(MockUdapSmartServer.parsed_io_body(request))
        )
      end

      def make_response
        parsed_body = MockUdapSmartServer.parsed_io_body(request)
        client_id = MockUdapSmartServer.client_uri_to_client_id(client_uri_from_registration_payload(parsed_body))
        ss_jwt = request_software_statement_jwt(parsed_body)

        response_body = {
          client_id:,
          software_statement: ss_jwt
        }
        response_body.merge!(MockUdapSmartServer.jwt_claims(ss_jwt).except(['iss', 'sub', 'exp', 'iat', 'jti']))

        response.body = response_body.to_json
        response.headers['Cache-Control'] = 'no-store'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.content_type = 'application/json'
        response.status = 201
      end

      def update_result
        nil # never update for now
      end

      def tags
        [REGISTRATION_TAG, UDAP_TAG]
      end

      private

      def client_uri_from_registration_payload(reg_body)
        software_statement_jwt = request_software_statement_jwt(reg_body)
        return unless software_statement_jwt.present?

        MockUdapSmartServer.jwt_claims(software_statement_jwt)&.dig('iss')
      end

      def request_software_statement_jwt(reg_body)
        reg_body&.dig('software_statement')
      end
    end
  end
end
