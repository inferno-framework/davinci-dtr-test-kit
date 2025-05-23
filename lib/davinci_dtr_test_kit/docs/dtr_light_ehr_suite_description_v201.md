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

Inferno will simulate a DTR SMART App that will connect to the DTR Light EHR system under test. The tester will need to launch Inferno using an EHR launch. Once the connection between Inferno's simulated DTR SMART App and the DTR Light EHR under test is established, tests within this suite will make FHIR API requests corresponding to capabilities required by the [Light DTR EHR Capability Statement](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr) and check that the EHR's responses are conformant.

## Running the Tests

If you would like to try out the tests but don't have a Light DTR EHR implementation, you can run these tests against the [public instance of the Inferno Reference Server](https://inferno.healthit.gov/reference-server/r4/) by using the Inferno Reference Server preset in the test suite. In order to get the Inferno Reference Server to do an EHR launch, navigate to https://inferno.healthit.gov/reference-server/app/app-launch and use https://inferno.healthit.gov/suites/custom/smart/launch as the App Launch URL. When using the Inferno Reference Server preset for the DTR Light EHR test suite, note that the sample patient used for testing (`dtr_bundle_patient_pat015.json`) is focused on DTR-specific data and does not have the complete set of US Core data needed to pass all the US Core tests. In addition, this preset does not test the `create` or `update` tests for DTR QuestionnaireResponse resources and PAS Task resources.

In addition, if you would like to try out the DTR-specific SMART Launch tests, meaning the tests that check for DTR `fhirContext` conformance, but do not have a Light DTR EHR implementation, you can run these tests against an instance of Inferno running the DTR Smart App Test Suite as your Light DTR EHR. This process is described in the following steps:

1. In the tab with the Light DTR EHR Test Suite open, click "1 Authorization" test group and click "Run all tests". The FHIR Server Base Url should be `[URL prefix]/custom/dtr_smart_app/fhir` where `[URL prefix]` comes from the URL of the test session which will be of the form `[URL prefix]/dtr_smart_app/[session id]` and the EHR Launch Client ID should be `sample`. Click "Submit". Take note of the launch_uri provided by the following prompt.
2. In a separate tab from the DTR Light EHR Test Suite, pull up the Da Vinci DTR SMART App Test Suite and click "Run all tests".
3. Start off by launching it with "EHR Launch from Inferno" with a client_id of `sample` and a launch_uri provided by the DTR Light EHR prompt in step 1. Before clicking "Submit", change the SMART App Launch fhirContext input to be an array of strings, rather than the default JSON object since the DTR Light EHR tests use STU2.0 version of SMART Launch. The input should be `["Coverage/cov015","DeviceRequest/devreqe0470"]`. Click "Submit".
4. Right click on the link in the resulting popup and click "Open Link in New Window" to complete the Authorization Test Group of the DTR Light EHR Test Suite.

## Limitations

The DTR IG is a complex specification and these tests currently validate conformance to only
a subset of IG requirements. Future versions of the test suite will test further
features.

## DTR 2.0.1 Corrections

The DTR 2.0.1 version of the [Light EHR CapabilityStatement](http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/light-dtr-ehr) includes two pieces of missing or misleading information that have been corrected:

- The 2.0.1 CapabilityStatement indicates that support for the [Coverage resource type](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr.html#coverage) is required when the [QuestionnaireResponse resource type was intended](https://build.fhir.org/ig/HL7/davinci-dtr/CapabilityStatement-light-dtr-ehr-311.html#questionnaireresponse) (note specifically that the `context` search parameters are not present on the Coverage resource type but is on the QuestionnaireResponse resource type).
- The 2.0.1 CapabilityStatement does not indicate a target profile for the [Task resource type](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr.html#task) but the current version [clarifies](https://build.fhir.org/ig/HL7/davinci-dtr/CapabilityStatement-light-dtr-ehr-311.html#task) that the [PAS Task Profile](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-task) is intended.

This test suite verifies systems according to these corrections. Additionally, it verifies the `read` interaction for the Coverage resource type.
