require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRPAYERRegistrationConfigurationDisplay < Inferno::Test
    include URLs

    id :dtr_client_payer_reg_config_display
    title 'Confirm client configuration'
    description %(
        This test provides all the information needed for testers to configure
        the client under test to communicate with Inferno's simulated PAS server
        include Authentication endpoints.
      )
    input :udap_client_uri,
          optional: true
    input :jwk_set,
          optional: true
    input :client_id,
          optional: true
    input :session_url_path,
          optional: true

    output :session_url_path

    run do
      new_session_url_path = nil
      if client_id.present?
        wait_identifier = client_id

        # blank out the session_url_path if an auth approach is configured
        if session_url_path.present?
          add_message('info',
                      '"Session-specific URL path extension" input value ignored - auth information provided.')
          new_session_url_path = ''
        end
        udap_smart_or_both =
          if udap_client_uri.present? && jwk_set.present?
            'SMART and UDAP'
          elsif udap_client_uri.present?
            'UDAP'
          else
            'SMART'
          end
        wait_message = %(
            **Inferno Simulated Server Details**:

            FHIR Base URL: `#{fhir_base_url}`
            Authentication Details:
            - Client Id (#{udap_smart_or_both}): `#{client_id}`
            - Token endpoint: `#{token_url}`

            [Click here](#{resume_pass_url}?token=#{wait_identifier}) once you have configured
            the client to connect to Inferno at the above endpoints.
          )
      else
        new_session_url_path = test_session_id if session_url_path.blank?
        wait_identifier = session_url_path || new_session_url_path
        wait_message = %(
            **Inferno Simulated Server Details**:

            FHIR Base URL: `#{session_fhir_base_url(wait_identifier)}`

            [Click here](#{resume_pass_url}?token=#{wait_identifier}) once you have configured
            the client to connect to Inferno at the above endpoints.
          )
      end
      output(session_url_path: new_session_url_path) unless new_session_url_path.nil?

      wait(
        identifier: wait_identifier,
        message: wait_message
      )
    end
  end
end
