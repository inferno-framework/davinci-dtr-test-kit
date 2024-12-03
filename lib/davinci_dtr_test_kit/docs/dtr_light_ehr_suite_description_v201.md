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

Inferno will simulate a DTR SMART App that will connect to the DTR Light EHR system under test. The tester will need to launch Inferno using either an EHR launch or a Standalone launch.

Once the connection between the DTR SMART App and the DTR Light EHR is established, tests within this suite check that the DTR Light EHR API is conformant to US Core and any other requirements outlined in the [Light DTR EHR Capability Statement](https://hl7.org/fhir/us/davinci-dtr/STU2/CapabilityStatement-light-dtr-ehr.html#root).

## Running the Tests

If you would like to try out the tests but don't have a DTR Light EHR implementation, you can run these tests against the [public instance of the Inferno Reference Server](https://inferno.healthit.gov/reference-server/r4/) by using the Inferno Reference Server preset in the test suite.

In order to get the Inferno QA Reference Server to do an EHR launch, navigate to https://inferno.healthit.gov/reference-server/app/app-launch and use https://inferno.healthit.gov/custom/smart/launch as the App Launch URL.

## Limitations

The DTR IG is a complex specification and these tests currently validate conformance to only
a subset of IG requirements. Future versions of the test suite will test further
features.

Additionally, the DTR IG has two notable discrepancies in the 2.0.1 version, particularly in the RESTful capabilities by Resource/Profile section. First,
v2.0.1's section on Coverage appears to be inconsistent with whether `context`
and `patient` search parameters are supported by the CRD Coverage Profile or the
DTR QuestionnaireResponse profile. The [CRD Coverage Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage) does not define search parameters, so this test suite tests for `read` capability of the CRD Coverage profile ONLY. Instead, this test suite tests for `read`, `create`, `update`, and `search-type` capabilities of the [DTR QuestionnaireResponse](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse) profile. Second, v2.0.1's section on Task capabilities does not appear to include a Supported Profile. For this test suite, the [CDex Task Profile](http://hl7.org/fhir/us/davinci-cdex/StructureDefinition/cdex-task-attachment-request) is used for validation.
