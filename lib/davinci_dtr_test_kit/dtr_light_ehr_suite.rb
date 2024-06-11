require_relative 'version'

module DaVinciDTRTestKit
  class DTRLightEHRSuite < Inferno::TestSuite
    id :dtr_light_ehr
    title 'Da Vinci DTR Light EHR Test Suite'
    description %(
        # Da Vinci DTR Light EHR Test Suite

        This suite validates that an EMR or other application
        can act as a data source for a DTR SMART App. Inferno
        will act as a DTR SMART App making requests for data
        against the system under test and storing completed
        questionnaire responses.
      )

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

    # These inputs will be available to all tests in this suite
    input :url,
          title: 'FHIR Server Base Url'

    input :credentials,
          title: 'OAuth Credentials',
          type: :oauth_credentials,
          optional: true

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
      oauth_credentials :credentials
    end

    # Hl7 Validator Wrapper:
    fhir_resource_validator do
      igs 'hl7.fhir.us.davinci-dtr#2.0.1'

      exclude_message do |message|
        message.message.match?(/\A\S+: \S+: URL value '.*' does not resolve/)
      end
    end
  end
end
