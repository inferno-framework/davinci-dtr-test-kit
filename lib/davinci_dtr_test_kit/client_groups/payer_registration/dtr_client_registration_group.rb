require 'udap_security_test_kit'
require 'smart_app_launch_test_kit'
require_relative '../../dtr_client_options'
require_relative 'configuration_display_smart_test'
require_relative 'configuration_display_udap_test'

module DaVinciDTRTestKit
  class DTRPayerRegistrationGroup < Inferno::TestGroup
    id :dtr_client_payer_registration
    title 'Client Registration'
    description %(
        Register the client under test with Inferno's simulated DTR Server,
        including configuration of the system under test to hit the correct endpoints and
        enable authentication and authorization of DTR requests.

        When running these tests there are two options for authentication:
        1. **UDAP B2B client credentials flow**: the system under test will dynamically register
           with Inferno and request access tokens used to access FHIR endpoints
           as per the UDAP specification.
        2. **SMART Backend Services**: the system under test will manually register
           with Inferno and request access token used to access FHIR endpoints
           as per the SMART Backend Services specification.
      )
    run_as_group

    # smart registration tests
    test from: :smart_client_registration_bsca_verification,
         required_suite_options: {
           client_type: DTRClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
         }
    test from: :dtr_client_payer_reg_smart_config_display,
         required_suite_options: {
           client_type: DTRClientOptions::SMART_BACKEND_SERVICES_CONFIDENTIAL_ASYMMETRIC
         }

    # udap registration tests
    test from: :udap_client_registration_interaction,
         required_suite_options: {
           client_type: DTRClientOptions::UDAP_CLIENT_CREDENTIALS
         },
         config: {
           options: { endpoint_suite_id: :dtr_full_ehr }
         }
    test from: :udap_client_registration_cc_verification,
         required_suite_options: {
           client_type: DTRClientOptions::UDAP_CLIENT_CREDENTIALS
         },
         config: {
           options: { endpoint_suite_id: :dtr_full_ehr }
         }
    test from: :dtr_client_payer_reg_udap_config_display,
         required_suite_options: {
           client_type: DTRClientOptions::UDAP_CLIENT_CREDENTIALS
         }
  end
end
