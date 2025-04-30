require 'smart_app_launch_test_kit'

module DaVinciDTRTestKit
  class DTRClientPayerTokenRequestSMARTVerification <
    SMARTAppLaunch::SMARTClientTokenRequestBackendServicesConfidentialAsymmetricVerification
    id :dtr_client_payer_auth_token_smart_verification

    def client_suite_id
      DaVinciDTRTestKit::DTRFullEHRSuite.id
    end
  end
end
