require 'tls_test_kit'
require_relative 'version'
require_relative 'dtr_options'
require 'smart_app_launch/smart_stu1_suite'
require 'smart_app_launch/smart_stu2_suite'

module DaVinciDTRTestKit
  class DTRLightEHRSuite < Inferno::TestSuite
    id :dtr_light_ehr
    title 'Da Vinci DTR Light EHR Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_light_ehr_suite_description_v201.md'))

    version VERSION

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
        url: 'https://hl7.org/fhir/us/davinci-dtr/STU2/'
      }
    ]

    input :url,
          title: 'FHIR Endpoint',
          description: 'URL of the DTR FHIR server'

    group do
      title 'Authorization'

      group from: :smart_discovery_stu2 do
        required_suite_options DTROptions::SMART_2_REQUIREMENT
        run_as_group

        test from: :tls_version_test do
          title 'DTR FHIR Server is secured by transport layer security'
          description <<~DESCRIPTION
            Under [Privacy, Security, and Safety](https://hl7.org/fhir/us/davinci-crd/STU2/security.html),
            the DTR Implementation Guide imposes the following rule about TLS:
            As per the [DTR Hook specification](https://cds-hooks.hl7.org/2.0/#security-and-safety),
            communications between DTR Clients and DTR Servers SHALL
            use TLS. Mutual TLS is not required by this specification but is permitted. DTR Servers and
            DTR Clients SHOULD enforce a minimum version and other TLS configuration requirements based
            on HRex rules for PHI exchange.
            This test verifies that the FHIR server is using TLS 1.2 or higher.
          DESCRIPTION

          id :dtr_server_tls_version_stu2

          config(
            options: { minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
          )
        end
      end

      group from: :smart_ehr_launch_stu2,
            required_suite_options: DTROptions::SMART_2_REQUIREMENT,
            run_as_group: true

      group from: :smart_standalone_launch_stu2,
            required_suite_options: DTROptions::SMART_2_REQUIREMENT,
            run_as_group: true
    end
  end
end
