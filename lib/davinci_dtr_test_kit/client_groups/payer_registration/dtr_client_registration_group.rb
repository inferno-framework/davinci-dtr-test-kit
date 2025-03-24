require_relative 'dtr_client_registration_configuration_display_test'
require_relative 'dtr_client_registration_other_auth_attest_test'
require_relative 'dtr_client_registration_udap_interaction_test'
require_relative 'dtr_client_registration_udap_verification_test'
require_relative 'dtr_client_registration_smart_verification_test'

module DaVinciDTRTestKit
  class DTRPAYERRegistrationGroup < Inferno::TestGroup
    id :dtr_client_payer_registration
    title 'Client Registration'
    description %(
        Register the client under test with Inferno's simulated PAS Server,
        including configuration of the system under test to hit the correct endpoints and
        enable authentication and authorization of PAS requests.

        If this set of tests is not run before the other tests, Inferno will default to use
        the **Dedicated Endpoints** approach using the session identifier to create the custom
        endpoints.

        When running these tests there are 4 options for authentication:
        1. **UDAP B2B client credentials flow**: the system under test will dynamically register
           with Inferno and request access tokens used to access FHIR endpoints
           as per the UDAP specification.
        2. **SMART Backend Services**: the system under test will manually register
           with Inferno and request access token used to access FHIR endpoints
           as per the SMART Backend Services specification.
        3. **Both UDAP and SMART**: the system under test will register as both a SMART
           and a UDAP client, using the same client id for both. If this path is chosen
           both authentication approaches will need to be demonstrated during the
           subsequent tests.
        4. **Dedicated Endpoints**: Inferno will create a dedicated set of FHIR endpoints for this session
           so that the system under test does not need to get access tokens or provide
           them during these tests. Since PAS requires authentication of client systems,
           testers will be asked to attest that their system supports another form of
           authentication, such as mutual authentication TLS.
      )
    run_as_group

    input :udap_client_uri,
          title: 'UDAP Client URI',
          type: 'text',
          optional: true,
          description: %(
              Required if demonstrating the UDAP B2B client credentials flow. Must be the
              Client URI that will be used to register with Inferno's simulated UDAP server.
            )
    input :jwk_set,
          title: 'JSON Web Key Set (JWKS)',
          type: 'textarea',
          optional: true,
          description: %(
              Required if demonstrating the SMART backend services flow. May be either
              a publicly accessible url containing the JWKS, or the raw JWKS.
            )
    input :client_id,
          title: 'Client Id',
          type: 'text',
          optional: true,
          description: %(
              If demonstrating only the SMART backend
              services flow and a particular client id is desired, put it here. If
              demonstrating the UDAP B2B client credentials flow as well, any value placed
              here will be overriden and the same client id as generated for UDAP will be used.
            )
    input :session_url_path,
          title: 'Session-specific URL path extension',
          type: 'text',
          optional: true,
          description: %(
              Ignored if a UDAP Client URI or JWKS is provided. If demonstrating PAS
              interactions without authentication, Inferno will use this value to
              setup a session-specific FHIR endpoints to use during these tests.
              If not provided, and no auth configuration is included in the inputs,
              a value will be generated.
            )
    group do
      id :dtr_client_payer_registration_udap
      title 'UDAP Registration'
      description %(
          If UDAP authentication will be demonstrated, perform the UDAP registration.
        )

      test from: :dtr_client_payer_reg_udap_interaction
      test from: :dtr_client_payer_reg_udap_verification
    end

    group do
      id :dtr_client_payer_registration_smart
      title 'SMART Registration'
      description %(
          If SMART authentication will be demonstrated, perform the SMART registration.
        )

      test from: :dtr_client_payer_reg_smart_verification
    end

    group do
      id :dtr_client_payer_registration_config
      title 'Client Configuration Confirmation'
      description %(
          Confirm client configuration.
        )
      test from: :dtr_client_payer_reg_other_auth_attest
      test from: :dtr_client_payer_reg_config_display
    end
  end
end
