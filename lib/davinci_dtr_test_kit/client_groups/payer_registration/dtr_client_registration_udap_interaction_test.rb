require 'udap_security_test_kit'

module DaVinciDTRTestKit
  class DTRPayerRegistrationUDAPInteraction < UDAPSecurityTestKit::UDAPClientRegistrationInteraction
    id :dtr_client_payer_reg_udap_interaction

    def client_suite_id
      DaVinciDTRTestKit::DTRFullEHRSuite.id
    end
  end
end
