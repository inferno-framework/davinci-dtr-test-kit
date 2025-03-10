require_relative 'version'

module DaVinciDTRTestKit
  class Metadata < Inferno::TestKit
    id :davinci_dtr_test_kit
    title 'Da Vinci Documentation Templates and Rules (DTR) Test Kit'
    description <<~DESCRIPTION
      The Da Vinci Documentation Templates and Rules (DTR) Test Kit validates
      the conformance of DTR SMART app client and payer server implementations to
      [version 2.0.1 of the Da Vinci DTR Implementation
      Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

      <!-- break -->

      ## Status

      These tests are a **DRAFT** intended to allow DTR implementers to perform
      preliminary checks of their implementations against the DTR IG requirements and
      provide feedback on the tests. Future versions of these tests may validate other
      requirements and may change how these are tested.

      ## Test Scope and Limitations

      The DTR Test Kit includes suites for the following DTR actors:
      - **DTR Payer Server**: verifies the ability of a payer server to respond
        to requests for questionnaires.
      - **DTR SMART App**: verifies the ability of a SMART app to launch, get questionnaires
        from a payer server, render them, and allow users to complete them.
      - **Full DTR EHR**: verifies the ability of a EHR to get questionnaires
        from a payer server, render them, and allow users to complete them.
      - **Light DTR EHR**: verifies the ability of a EHR to launch a DTR SMART
        app and respond to FHIR data gathering requests.

      Documentation of the current tests and their limitations can be found in each
      suite's description when the tests are run and can also be viewed in the
      source code:
      - [SMART App Test Suite Limitations](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/docs/dtr_smart_app_suite_description_v201.md)
      - [Payer Server Test Suite Limitations](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/docs/dtr_payer_server_suite_description_v201.md)
      - [Full DTR EHR Test Suite Limitations](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/docs/dtr_full_ehr_suite_description_v201.md)
      - [Light DTR EHR Test Suite Limitations](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/docs/dtr_light_ehr_suite_description_v201.md)

      ### Test Scope

      To validate the behavior of the system under test, Inferno will act as an
      exchange partner. Specifically,

      - **When testing a DTR SMART app client**: Inferno will simulate both a payer
        server that can return questionnaires and a Light DTR EHR that can respond
        to queries for clinical data used to pre-populate questionnaire responses.
        Inferno uses the SMART App Launch framework to establish a connection with
        the app under test, either in EHR Launch or Standalone Launch mode. The app
        will be expected to initiate requests to Inferno and demonstrate its ability
        to react to the returned responses. Over the course of these interactions,
        Inferno will seek to observe the conformant completion of a questionnaire
        including pre-population, as well as the ability of the app to correctly
        render the questionnaire and allow users to interact with it.
      - **When testing a DTR payer server**: Inferno will simulate a DTR app
        by requesting questionnaires from the server under test. The server
        will be expected to respond to these requests from Inferno. Over the course
        of these interactions, Inferno will seek to observe the ability of the
        server under test to return conformant questionnaires.
      - **When testing a Full DTR EHR client**: Inferno will simulate a payer
        server that can return questionnaires. The EHR will be expected to initiate
        requests to Inferno and demonstrate its ability to react to the returned
        responses. Over the course of these interactions,
        Inferno will seek to observe the conformant completion of a questionnaire
        including fetch, as well as the ability of the app to correctly
        render the questionnaire and allow users to interact with it.
      - **When testing a Light DTR EHR server**: Inferno will simulate a DTR SMART app
        that tested servers can launch and that will request FHIR data from and create
        and update QuestionnaireResponse and Task instances on the server under test.
        Over the course of these interactions, Inferno will seek to observe the ability of the
        server under test to conformantly serve as a FHIR server for a DTR SMART App.

      ### Known Limitations

      - **SMART app tests**:
        - Some questionnaire features, including adaptive questionnaires, are not yet tested.
        - Inferno uses a single FHIR endpoint to simulate both the payer and the EHR.
      - **Payer server tests**:
        - Inferno checks that CQL is used for pre-population in the questionnaires returned by the
          payer server, but does not currently validate the correctness or executability of that CQL.
      - **Full EHR tests**:
        - Some questionnaire features are not yet tested.
        - Non-standard approach to accessing QuestionnaireResponse instances for validation.
      - **Light EHR tests**:
        - `fhirContext` not tested as a part of the Light EHR's SMART App launch process.

      ## Reporting Issues

      Please report any issues with this set of tests in the [GitHub
      Issues](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
      section of the
      [open-source code repository](https://github.com/inferno-framework/davinci-dtr-test-kit).
    DESCRIPTION
    suite_ids [:dtr_payer_server, :dtr_smart_app, :dtr_full_ehr, :dtr_light_ehr]
    tags ['Da Vinci', 'DTR']
    last_updated LAST_UPDATED
    version VERSION
    maturity 'Low'
    authors ['Karl Naden', 'Tom Strassner', 'Robert Passas', 'Vanessa Fotso', 'Elsa Perelli']
    repo 'https://github.com/inferno-framework/davinci-dtr-test-kit'
  end
end
