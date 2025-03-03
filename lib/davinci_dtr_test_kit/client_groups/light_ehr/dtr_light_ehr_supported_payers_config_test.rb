require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayersConfigTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_sp_config
    title 'Demonstrate supported payers configuration'
    description %(
      During this test the capability of the light EHR under test to configure a supported
      payers endpoint for Inferno's simulated DTR SMART App.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@105'

    input :unique_url_id, type: :text

    run do
      identifier = SecureRandom.hex(32)
      wait(
        identifier:,
        message: <<~MESSAGE
          Show that the Light EHR under test has been configured to use the following URL
          as the supported payers endpoint for Inferno's simulated DTR SMART App:

          `#{supported_payer_url(unique_url_id)}`

          [Click here](#{resume_pass_url}?token=#{identifier}) if the system **successfully** demonstrates this configuration.

          [Click here](#{resume_fail_url}?token=#{identifier}) if the system **does not** demonstrate this configuration.
        MESSAGE
      )
    end
  end
end
