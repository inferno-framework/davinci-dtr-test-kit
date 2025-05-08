require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRPayerRegistrationConfigurationUDAPDisplay < Inferno::Test
    include URLs

    id :dtr_client_payer_reg_udap_config_display
    title 'Confirm client configuration'
    description %(
      This test provides all the information needed for testers to configure
      the client under test to communicate with Inferno's simulated PAS server
      including UDAP endpoints to obtain access tokens.
    )

    input :client_id

    run do
      wait(
        identifier: client_id,
        message: %(
          **Inferno Simulated Server Details**:

          FHIR Base URL: `#{fhir_base_url}`

          Authentication Details:
          - UDAP Client Id: `#{client_id}`
          - Token endpoint: `#{token_url}`

          [Click here](#{resume_pass_url}?token=#{client_id}) once you have configured
          the client to connect to Inferno at the above endpoints.
        )
      )
    end
  end
end
