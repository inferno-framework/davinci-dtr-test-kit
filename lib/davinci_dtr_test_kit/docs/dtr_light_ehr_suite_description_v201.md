The Da Vinci DTR Test Kit Light EHR Suite validates the conformance of SMART apps
to the STU 2 version of the HL7® FHIR®
[Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

## Scope

These tests are a **DRAFT** intended to allow app implementers to perform
preliminary checks of their systems against DTR IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a DTR SMART App that will connect to the DTR Light EHR system under test. The tester will need to launch Inferno using either an EHR launch or a Standalone launch. Once the connection between Inferno's simulated DTR SMART App and the DTR Light EHR under test is established, tests within this suite will make FHIR API requests corresponding to capabilities required by the [Light DTR EHR Capability Statement](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr) and check that the EHR's responses are conformant.

## Running the Tests

If you would like to try out the tests but don't have a DTR Light EHR implementation, you can run these tests against the [public instance of the Inferno Reference Server](https://inferno.healthit.gov/reference-server/r4/) by using the Inferno Reference Server preset in the test suite. In order to get the Inferno Reference Server to do an EHR launch, navigate to https://inferno.healthit.gov/reference-server/app/app-launch and use https://inferno.healthit.gov/suites/custom/smart/launch as the App Launch URL. When using the Inferno Reference Server preset for the DTR Light EHR test suite, note that the sample patient used for testing (`dtr_bundle_patient_pat015.json`) is focused on DTR-specific data and does not have the complete set of US Core data needed to pass all the US Core tests. In addition, this preset does not test the `create` or `update` tests for DTR QuestionnaireResponse resources and PAS Task resources.

## Limitations

The DTR IG is a complex specification and these tests currently validate conformance to only
a subset of IG requirements. Future versions of the test suite will test further
features.

Specific limitations include:
- *SMART Launch `fhirContext`*: Inferno does not currently verify the use of `fhirContext` to convey details
  about the DTR SMART App launch.

## DTR 2.0.1 Corrections

The DTR 2.0.1 version of the [Light EHR CapabilityStatement](http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/light-dtr-ehr) includes two pieces of missing or misleading information that have been corrected:

- The 2.0.1 CapabilityStatement indicates that support for the [Coverage resource type](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr.html#coverage) is required when the [QuestionnaireResponse resource type was intended](https://build.fhir.org/ig/HL7/davinci-dtr/CapabilityStatement-light-dtr-ehr-311.html#questionnaireresponse) (note specifically that the `context` search parameters are not present on the Coverage resource type but is on the QuestionnaireResponse resource type).
- The 2.0.1 CapabilityStatement does not indicate a target profile for the [Task resource type](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr.html#task) but the current version [clarifies](https://build.fhir.org/ig/HL7/davinci-dtr/CapabilityStatement-light-dtr-ehr-311.html#task) that the [PAS Task Profile](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-task) is intended.

This test suite verifies systems according to these corrections. Additionally, it verifies the `read` interaction for the Coverage resource type.
