require 'smart_app_launch_test_kit'
require_relative 'interaction_test'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRPayerServerSuiteV220 < Inferno::TestSuite
      id :dtr_payer_server_v220
      title 'Da Vinci DTR Client Simulator Suite v2.2.0' # Payer Server v2.2.0 Test Suite' - currently no verification, just simulation  # rubocop:disable Layout/LineLength
      description File.read(File.join(__dir__, 'dtr_payer_server_suite_description_v220.md'))

      links [
        {
          label: 'Report Issue',
          url: 'https://github.com/inferno-framework/davinci-dtr-test-kit/issues'
        },
        {
          label: 'Open Source',
          url: 'https://github.com/inferno-framework/davinci-dtr-test-kit'
        },
        {
          label: 'Download',
          url: 'https://github.com/inferno-framework/davinci-dtr-test-kit/releases'
        },
        {
          label: 'Implementation Guide',
          url: 'https://hl7.org/fhir/us/davinci-dtr/2.2.0/'
        }
      ]

      # requirement_sets(
      #   {
      #     identifier: 'hl7.fhir.us.davinci-dtr_2.0.1',
      #     title: 'Da Vinci Documentation Templates and Rules (DTR) v2.0.1',
      #     actor: 'Payer Service'
      #   }
      # )

      fhir_resource_validator do
        igs('hl7.fhir.us.davinci-dtr#2.2.0')

        exclude_message do |message|
          message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
        end
      end

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'

      group from: :'smart_stu2-smart_backend_services'

      group do
        id :dtr_payer_server_v220_questionnaires
        title 'Payer serves Questionnaires'
        run_as_group

        input :backend_services_smart_auth_info,
              title: 'OAuth Credentials',
              type: :auth_info,
              optional: true

        fhir_client do
          url :url
          auth_info :backend_services_smart_auth_info
        end

        test from: :dtr_v220_payer_interaction
      end
    end
  end
end
