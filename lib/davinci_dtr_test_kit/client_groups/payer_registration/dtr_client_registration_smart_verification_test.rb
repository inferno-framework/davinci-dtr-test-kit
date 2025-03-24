require_relative '../../tags'
require_relative '../../urls'
require_relative '../../endpoints/mock_udap_smart_server'

module DaVinciDTRTestKit
  class DTRPAYERRegistrationSMARTVerification < Inferno::Test
    include URLs

    id :dtr_client_payer_reg_smart_verification
    title 'Verify SMART Registration'
    description %(
        During this test, Inferno will verify that the SMART registration details
        provided are conformant.
      )
    input :jwk_set,
          optional: true
    input :client_id,
          optional: true

    output :client_id

    run do
      omit_if jwk_set.blank?, 'Not configured for SMART authentication.'

      if client_id.blank?
        client_id = test_session_id
        output(client_id:)
      end

      jwks_warnings = []
      parsed_jwk_set = MockUdapSmartServer.jwk_set(jwk_set, jwks_warnings)
      jwks_warnings.each { |warning| add_message('warning', warning) }

      assert parsed_jwk_set.length.positive?, 'JWKS content does not include any valid keys.'

      # store_mocked_registration(JWT::JWK::Set.new(jwk_list))

      # TODO: add key-specific verification per end of https://build.fhir.org/ig/HL7/smart-app-launch/client-confidential-asymmetric.html#registering-a-client-communicating-public-keys

      assert messages.none? { |msg| msg[:type] == 'error' }, 'Invalid key set provided. See messages for details'
    end

    def store_mocked_registration(jwks_set)
      # TODO: add more details and fix
      response_body = {
        client_id:,
        jwks: jwks_set.export.to_json
      }
      request_params = {
        direction: 'incoming',
        verb: :post,
        url: REGISTRATION_PATH,
        test_session_id:,
        result_id: 'replace_me',
        response_body: response_body.to_json,
        tags: [REGISTRATION_TAG, SMART_TAG]
      }
      Inferno::Repositories::Requests.new.create(request_params)
    end
  end
end
