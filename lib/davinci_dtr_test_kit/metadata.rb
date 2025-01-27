require_relative 'version'

module DaVinciDTRTestKit
  class Metadata < Inferno::TestKit
    id :davinci_dtr_test_kit
    title 'DaVinci DTR Test Kit'
    description <<~DESCRIPTION
      The Da Vinci Documentation Templates and Rules (DTR) Test Kit validates the
      conformance of systems to the
      [DTR STU 2.0.1 FHIR IG](https://hl7.org/fhir/us/davinci-dtr/STU2).
      The test kit includes suites targeting the following actors from the specification:

      - **Payer Servers**: Inferno will act as a client and make a series of
        requests to the server under test requesting questionnaires.
      - **DTR SMART App**: Inferno will act as a server implementing the
        payer server and light EHR capabilities and responding to requests
        for questionnaires and clinical data made by the app under test.
      - **DTR Full EHR**: Inferno will act as a server implementing the
        payer server responding to requests for questionnaires made by
        the EHR under test.
      - **DTR Light EHR**: Inferno will act as a DTR SMART App that will connect
        to the DTR Light EHR system under test and make requests to the Light EHR under test.

      In each case, content provided by the system under test will be checked individually
      for conformance and in aggregate to determine that the full set of features is
      supported.
      <!-- break -->
    DESCRIPTION
    suite_ids [:dtr_payer_server, :dtr_smart_app, :dtr_full_ehr, :dtr_light_ehr]
    tags ['SMART App Launch', 'US Core', 'DTR']
    last_updated '2025-01-27'
    version VERSION
    maturity 'Low'
    authors ['Karl Naden', 'Tom Strassner', 'Robert Passas', 'Vanessa Fotso', 'Elsa Perelli']
    repo 'https://github.com/inferno-framework/davinci-dtr-test-kit'
  end
end
