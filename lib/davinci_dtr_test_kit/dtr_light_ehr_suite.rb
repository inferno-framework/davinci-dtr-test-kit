require 'tls_test_kit'
require_relative 'version'
require_relative 'dtr_options'
require 'smart_app_launch/smart_stu1_suite'
require 'smart_app_launch/smart_stu2_suite'

module DaVinciDTRTestKit
  class DTRLightEHRSuite < Inferno::TestSuite
    id :dtr_light_ehr
    title 'Da Vinci DTR Light EHR Test Suite'
    description <<~DESCRIPTION
      The Da Vinci DTR Test Kit Light EHR Suite validates the conformance of SMART apps
      to the STU 2 version of the HL7® FHIR®
      [Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

      ## Scope

      These tests are a **DRAFT** intended to allow app implementers to perform
      preliminary checks of their systems against DTR IG requirements and [provide
      feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
      on the tests. Future versions of these tests may validate other requirements and may change the test validation logic.

      ## SMART App Launch

      Use this information when registering Inferno as a SMART App:

      * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      If a client receives a SMART App Launch card in a response and would like
      to test their ability to launch Inferno as a SMART App, first run the
      SMART on FHIR Discovery and SMART EHR Launch groups under FHIR API >
      Authorization. When running the SMART EHR Launch group, Inferno will wait
      for the incoming SMART App Launch request, and this is the time to perform
      the launch from the client being tested.

      ## Running the Tests

      ## Limitations

      The DTR IG is a complex specification and these tests currently validate conformance to only
      a subset of IG requirements. Future versions of the test suite will test further
      features. A few specific features of interest are listed below.
    DESCRIPTION

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
