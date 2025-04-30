require 'udap_security_test_kit'

module DaVinciDTRTestKit
  class DTRPayerRegistrationUDAPVerification <
      UDAPSecurityTestKit::UDAPClientRegistrationClientCredentialsVerification
    id :dtr_client_payer_reg_udap_verification

    def client_suite_id
      DaVinciDTRTestKit::DTRFullEHRSuite.id
    end
  end
end
