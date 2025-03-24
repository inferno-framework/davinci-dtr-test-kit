require_relative 'dtr_client_payer_udap_token_request_test'
require_relative 'dtr_client_payer_udap_token_use_test'
require_relative 'dtr_client_payer_smart_token_request_test'
require_relative 'dtr_client_payer_smart_token_use_test'

module DaVinciDTRTestKit
  class DTRClientPayerAuthGroup < Inferno::TestGroup
    id :dtr_client_payer_auth
    title 'Review Authentication Interactions'
    description %(
        During these tests, Inferno will verify that the client interacted with Inferno's
        simulated authorization server in a conformant manner when requesting access tokens
        and that the client under test was able to use provided access tokens to make PAS
        requests.

        Before running these tests, perform at least one PAS workflow group so that the client
        will request an access token and use it on a PAS request.

        This group will be omitted if using dedicated endpoints for session authentication.
      )
    run_as_group

    group do
      id :dtr_client_payer_auth_udap
      title 'Verify UDAP Authentication'

      test from: :dtr_client_payer_udap_token_request_test
      test from: :dtr_client_payer_udap_token_use_test
    end

    group do
      id :dtr_client_payer_auth_smart
      title 'Verify SMART Authentication'

      test from: :dtr_client_payer_smart_token_request_test
      test from: :dtr_client_payer_smart_token_use_test
    end
  end
end
