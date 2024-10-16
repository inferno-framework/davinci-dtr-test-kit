The Da Vinci DTR Test Kit Full EHR Suite validates the conformance of SMART apps
to the STU 2 version of the HL7® FHIR®
[Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

## Scope

These tests are a **DRAFT** intended to allow app implementers to perform
preliminary checks of their systems against DTR IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a DTR SMART App that will get launched by the DTR Light EHR System under test. The DTR Light EHR will be expected to properly launch the DTR SMART App.

Once the connection between the DTR SMART App and the DTR Light EHR is established, tests within this suite check that the DTR Light EHR API is conformant to US Core and any other requirements outlined in the [Light DTR EHR Capability Statement](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr.html#root).

## Running the Tests

If you would like to try out the tests but don't have a DTR payer server implementation, you can run these tests against the [public instance of the Inferno Reference Server](https://inferno-qa.healthit.gov/reference-server/r4/) by using the Inferno Reference Server preset in the test suite.

In order to get the Inferno QA Reference Server to do an EHR launch, navigate to https://inferno-qa.healthit.gov/reference-server/app/app-launch and use http://localhost:4567/custom/smart/launch as the App Launch URL.
