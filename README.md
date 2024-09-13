# Da Vinci Documentation Templates and Rules (DTR) v2.0.1 Test Kit

The Da Vinci Documentation Templates and Rules (DTR) STU 2.0.1 Test Kit validates the 
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

In each case, content provided by the system under test will be checked individually
for conformance and in aggregate to determine that the full set of features is
supported.

This test kit is [open source](#license) and freely available for use or
adoption by the health IT community including EHR vendors, health app
developers, and testing labs. It is built using the [Inferno
Framework](https://inferno-framework.github.io/). The Inferno Framework is
designed for reuse and aims to make it easier to build test kits for any
FHIR-based data exchange.

## Status

These tests are a **DRAFT** intended to allow DTR implementers to perform 
preliminary checks of their implementations against DTR IG requirements and provide 
feedback on the tests. Future versions of these tests may validate other 
requirements and may change how these are tested.

## Test Scope and Limitations

The DTR specification is complex and evolving and these tests do not yet
cover the full scope of the specification. In particular, tests have been 
started but not yet released Light DTR EMR actors responsible for launching
a DTR SMART App and serving data that the app can use to populate questionnaires.

For the implemented actors, see suite-specific documentation on current limitations
for the [payer server](lib/davinci_dtr_test_kit/docs/dtr_payer_server_suite_description_v201.md#limitations),
[DTR SMART App](lib/davinci_dtr_test_kit/docs/dtr_smart_app_suite_description_v201.md#limitations), 
[DTR Full EHR](lib/davinci_dtr_test_kit/docs/dtr_full_ehr_suite_description_v201.md#limitations)
tests

## How to Run

Use either of the following methods to run the suites within this test kit.
If you would like to try out the tests but don’t have a DTR implementation, 
the test home pages include instructions for trying out the tests, including

- For payer server testing: running the tests against the DTR SMART App tests in this Test Kit
- For DTR SMART App testing: a [sample postman collection](config/DTR%20SMART%20App%20Tests%20Postman%20Demo.postman_collection.json)
- For DTR Full EHR testing: [sample postman collection](config/DTR%20Full%20EHR%20Tests%20Postman%20Demo.postman_collection.json)

Detailed instructions can be found in the suite descriptions when the tests
are run or within this repository for the 
[payer server](lib/davinci_dtr_test_kit/docs/dtr_payer_server_suite_description_v201.md#running-the-tests), 
[DTR SMART App](lib/davinci_dtr_test_kit/docs/dtr_smart_app_suite_description_v201.md#running-the-tests),
and [DTR Full EHR](lib/davinci_dtr_test_kit/docs/dtr_full_ehr_suite_description_v201.md#running-the-tests).

### ONC Hosted Instance

You can run the DTR test kit via the [ONC Inferno](https://inferno.healthit.gov/test-kits/davinci-dtr/) website by choosing the “Da Vinci Documentation Templates and Rules (DTR) Test Kit” test kit.

### Local Inferno Instance

- Download the source code from this repository.
- [Start or identify](#fhir-server-simulation-for-the-client-suite) 
  an Inferno Reference Server instance for Inferno to use for simulation (only needed if
  planning to run the DTR SMART App test suite).
- Open a terminal in the directory containing the downloaded code.
- In the terminal, run `setup.sh`.
- In the terminal, run `run.sh`.
- Use a web browser to navigate to `http://localhost`.

## FHIR Server Simulation for the DTR SMART App Suite

The DTR SMART App test suite needs to be able to return responses to FHIR read and search APIs.
These responses can be complex and so the suite relies on a full FHIR server to provide 
responses for it to provide back to systems under test. The test kit was written to work 
with the [Inferno Reference Server](https://github.com/inferno-framework/inferno-reference-server)

- loaded with [patient pat015](https://github.com/inferno-framework/inferno-reference-server/blob/main/resources/dtr_bundle_patient_pat015.json)
- accepting bearer token `SAMPLE_TOKEN` for read access.

### Simulation Server Configuration For Local Test Kit Execution

The test kit can be configured to point to either a local instance of the reference server or
to a public instance. The location of the The following are valid configuration approaches:

1. Point to a public instance of the Inferno reference server at either 
   `https://inferno.healthit.gov/reference-server/r4/` or
   `https://inferno-qa.healthit.gov/reference-server/r4/`: update the `FHIR_REFERENCE_SERVER`
   environment variable in the appropriate environment file (`.evn.production` when running
   in docker [as above](#local-inferno-instance), or `env.development` when 
   [running the test kit in Ruby](#development)).
2. Run a local instance of the Inferno Reference Server, either 
   [with docker](https://github.com/inferno-framework/inferno-reference-server?tab=readme-ov-file#running-with-docker) 
   or [without docker](https://github.com/inferno-framework/inferno-reference-server?tab=readme-ov-file#running-without-docker) 
   (NOTE: this decision can be made independently from whether to run the test kit with 
   docker or using Ruby).

## Providing Feedback and Reporting Issues

We welcome feedback on the tests, including but not limited to the following areas:
- Validation logic, such as potential bugs, lax checks, and unexpected failures.
- Requirements coverage, such as requirements that have been missed and tests that necessitate features that the IG does not require.
- User experience, such as confusing or missing information in the test UI.

Please report any issues with this set of tests in the issues section of this repository.

## Development

To make updates and additions to this test kit, see the 
[Inferno Framework Documentation](https://inferno-framework.github.io/docs/),
particularly the instructions on 
[development with Ruby](https://inferno-framework.github.io/docs/getting-started/#development-with-ruby).

### Client Questionnaire Workflow Test Framework

To support testing that clients can fetch, populate, and complete various questionnaires with different features, the test kit includes a framework for building different iterations of these tests. At a high-level, the framework includes the ability to associate a set of fixtures with a group of tests including
- a questionnaire that will be sent back when the client makes a $questionnaire-package request
- a questionnaire response that contains expected pre-populated and overriden items. These are indicated by the origin.source extension on items with link ids corresponding to items in the questionnaire with cql expressions for pre-population. When it is `auto` that is the expected answer based on data Inferno has. When it is `override` that is the answer that would be present if the pre-populated answer were used, but Inferno will check that a different value is present since the tester will be expected to override the answer.

See logic in `mock_payer`, `dtr_questionnaire_response_validation`, and `fixture_loader`, among others.

### Additional Implementations

To exercise the test kit for the purposes of demoing or debugging, one option is to use the HL7 Da Vinci Documentation
Requirements Lookup Service (DRLS) reference implementation. Instructions to set up the reference implementation can be
found [here](https://github.com/HL7-DaVinci/CRD/blob/master/SetupGuideForMacOS.md). This setup includes downloading five
different git repositories. Note that changes are currently necessary to these components to allow
them to send requests to Inferno for the purposes of testing.

## License

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

## Trademark Notice

HL7, FHIR and the FHIR [FLAME DESIGN] are the registered trademarks of Health
Level Seven International and their use does not constitute endorsement by HL7.