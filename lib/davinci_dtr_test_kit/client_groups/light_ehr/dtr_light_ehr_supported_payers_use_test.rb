require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayersUseTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_sp_use
    title 'Demonstrate Use of the Supported Payers Response'
    description %(
      During this test the tester will demonstrate the ability of the light EHR under test to use the response from
      the supported payers endpoint to suppress the launch of Inferno's simulated DTR SMART App for a patient
      who is covered only by payers not included in the returned supported payers list.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@115'

    run do
      identifier = SecureRandom.hex(32)
      wait(
        identifier:,
        message: <<~MESSAGE
          Demonstrate that when DTR is needed for a patient that is not covered by payers included in the
          supported payers list returned from the endpoint, launching Inferno's simulated DTR App
          is not an option.

          [Click here](#{resume_pass_url}?token=#{identifier}) if the system **successfully** demonstrates this capability.

          [Click here](#{resume_fail_url}?token=#{identifier}) if the system **does not** demonstrate this capability.
        MESSAGE
      )
    end
  end
end
