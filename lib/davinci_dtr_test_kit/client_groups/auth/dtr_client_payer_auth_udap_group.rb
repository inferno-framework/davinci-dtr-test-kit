require 'udap_security_test_kit'
require_relative 'token_request_udap_verification_test'
require_relative '../../tags'

module DaVinciDTRTestKit
  class DTRClientPayerAuthUDAPGroup < Inferno::TestGroup
    id :dtr_client_payer_auth_udap
    title 'Review Authentication Interactions'
    description %(
        During these tests, Inferno will verify that the client interacted with Inferno's
        simulated udAP authorization server in a conformant manner when requesting access tokens
        and that the client under test was able to use provided access tokens to make DTR
        requests.

        Before running these tests, perform at least one DTR workflow group so that the client
        will request an access token and use it on a DTR request.
      )
    run_as_group

    # smart auth verification
    test from: :dtr_client_payer_auth_token_udap_verification
    test from: :udap_client_token_use_verification,
         config: {
           options: { access_request_tags: [QUESTIONNAIRE_PACKAGE_TAG, CLIENT_NEXT_TAG] }
         }
  end
end
