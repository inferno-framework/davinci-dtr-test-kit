The Da Vinci DTR Test Kit SMART App Suite validates the conformance of SMART apps
to the STU 2 version of the HL7® FHIR®
[Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

## Scope

These tests are a **DRAFT** intended to allow app implementers to perform
preliminary checks of their systems against DTR IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a DTR payer server and light EHR that will response to
requests for questionnaires and clinical data for the app under test to interact with. 
The app will be expected to initiate requests to Inferno to elicit responses. Over the
course of these interactions, Inferno will seek to observe conformant handling of 
DTR workflows and requirements around the retrieval, completion, and storage of
questionnaires.

Tests within this suite are associated with specific questionnaires that the app will
demonstrate completion of. In each case, the app under test will initiate a request to
the payer server simulated by Inferno for a questionnaire using the 
`$questionnaire-package` operation. Inferno will always return the specific questionnaire
for the test being executed regardless of the input provided by the app, though it must
be conformant. The app will then be asked to complete the questionnaire, including
- Pre-populating answers based on directives in the questionnaire, which includes the
  fetching of associated data from the light EHR simulated by Inferno
- Rendering the questionnaire for users and allowing them to make additional updates.
  These tests can include specific directions on details to include in the completed
  questionnaire.
- Storing the completed questionnaire back to the light EHR simulated by Inferno. Inferno
  will validate the stored questionnaire, including pre-populated values (Inferno knows
  the pre-population logic and the data used in calculation) and other conformance details.

Apps will be required to complete all questionnaires in the suite, which in aggregate
contain all questionnaire features that apps must support. Currently, the suite includes
two questionnaires:
1. A fictious "dinner" questionnaire created for these tests. It tests basic
   item rendering and pre-population.
2. A Respiratory Assist Device questionnaire pulled from the DTR reference implementation.
   It tests additional features and represents a more realistic questionnaire.
Additional questionnaires will be added in the future.

All requests sent by the app will be checked 
for conformance to the DTR IG requirements individually and used in aggregate to determine
whether required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

This test suite can be run in two modes, each described below:
1. [EHR launch mode](#ehr-launch)
2. [Standalone launch mode](#standalone-launch)

At this time, Inferno's simulation of the payer server that provides the questionnaires
uses the same base server url and access token, and apps will need to be configured to
connect to it as well. See the "Combined payer and EHR FHIR servers" section below for details.

The DTR specification allows apps and their partners significant leeway in terms of
what information is provided on launch and how that information gets used by the app
to determine the `$questionnaire-package` endpoint and what details to submit as a
part of that operation. Inferno cannot know ahead of time what data needs to be
available for the app under test to successfully request, pre-populate, and render 
a questionnaire. See the "`fhirContext` and available instances"
section below for details on how to enable Inferno to meet the needs of your application.

#### EHR Launch

In this mode Inferno will launch the app under test using the SMART App Launch
[EHR launch](https://hl7.org/fhir/smart-app-launch/STU2.1/app-launch.html#launch-app-ehr-launch)
flow. 

The tester must provide
1. a `client_id`: can be any string and will uniquely identify the testing session.
2. a `launch_uri`: will be used by Inferno to generate a link to launch the app under test.

All the details needed to access clinical data from Inferno's simulated EHR are provided
as a part of the SMART flow, including 
- the FHIR base server URL to request data from
- a bearer token to provide on all requests

#### Standalone Launch

In this mode the app under test will launch and on its own and reach out to Inferno to
begin the workflow as described in the 
[standalone launch section](https://hl7.org/fhir/smart-app-launch/STU2.1/app-launch.html#launch-app-standalone-launch).

The tester must provide
1. a `client_id`: can be any string and will uniquely identify the testing session.

The app will then need to connect to Inferno as directed to initiate the SMART and DTR
workflow. The FHIR base server url that app will connect to is 
`[URL prefix]/custom/dtr_smart_app/fhir` where `[URL prefix]` comes from the URL of the
test session which will be of the form `[URL prefix]/dtr_smart_app/[session id]`

### Postman-based Demo

If you do not have a DTR SMART app but would like to try the tests out, you can use
[this Postman collection](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/config/DTR%20SMART%20App%20Tests%20Postman%20Demo.postman_collection.json)
to make requests against Inferno. This does not include the capability to render the complete the
questionnaires, but does have samples of correctly and incorrectly completed QuestionnaireResponses.
The following is a list of tests with the Postman requests that can be used with them:

- **Standalone launch sequence**: use requests in the `SMART App Launch` folder during 
  tests **1.1.1.01** or **2.1.1.01** to simulate the SMART Launch flow and obtain an access
  token to use for subsequent requests. See the collection's Overview for details on the
  access token's generation.
- **1.1** *Static Questionnaire Workflow*: use requests in the `Static Dinner` folder
  - **1.1.1.01** *Invoke the DTR Questionnaire Package operation*: submit request `Questionnaire Package for Dinner (Static)` while this test is waiting.
  - **1.1.3.01** *Save the QuestionnaireResponse after completing it*: submit request `Save QuestionnaireResponse for Dinner (Static)` while this test is waiting. If you want to see a failure, submit request `Save QuestionnaireResponse for Dinner (Static) - missing origin extension` instead.
- **2.1** *Respiratory Assist Device Questionnaire Workflow*: use requests in the `Respiratory Assist Device` folder
  - **2.1.1.01** *Invoke the DTR Questionnaire Package operation*: submit request `Questionnaire Package for Resp Assist Device` while this test is waiting.
  - **2.1.3.01** *Save the QuestionnaireResponse after completing it*: submit request `Save Questionnaire Response for Resp Assist Device` while this test is waiting. If you want to see a failure, submit request `Save Questionnaire Response for Resp Assist Device - unexpected override` instead.

## Configuration Details

### `fhirContext` and available instances

Once they have launched, DTR SMART Apps obtain details that drive their retrieval of questionnaires
and relevant clinical data from the payer and the EHR from [context that is passed with
the access token](https://hl7.org/fhir/smart-app-launch/STU2.1/scopes-and-launch-context.html)
provided by the EHR. Inferno cannot know ahead of time what information to provide and
what instances to make available to direct the app under test to request and render a
particular questionnaire.

Therefore, use of this test suite requests that the tester provide this information so that the
app can demonstrate its capabilities based on whatever business logic is present. These tests
currently support two context parameters that contain references to instance in the EHR and provides
testers with a way to provide those instances to Inferno so it can serve them to the app. These are
controlled by the following inputs present on each group associated with a questionnaire:

- **SMART App Launch Patient ID**: provide an `id` for the subject Patient FHIR instance.
- **SMART App Launch `fhirContext`**: provide a JSON object containing FHIR references to instances
  relevant to the DTR workflow, e.g. 
  
  ```
  [{reference: 'Coverage/cov015'}, {reference: 'DeviceRequest/devreqe0470'}]
  ``` 
  This will be included under the `fhirContext` key of the token response.
- **EHR-available resources**: provide a Bundle containing FHIR instances referenced in and from the
  previous two inputs. Each instance must include an `id` element that Inferno will use in conjunction
  with the `resourceType` to make the instances available at the `[server base url]/[resourceType]/[id]`.

Each questionnaire workflow group description includes a link to the questionnaire package that Inferno will return
(e.g., [here](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_static/questionnaire_dinner_order_static.json))
where you can find `id` and `url` values and any other details needed to determine what inputs 
will allow the app under test to work with that questionnaire. Note additionally that Inferno will always
return that questionnaire in response to `$questionnaire-package` requests made during that test.

These inputs can be cumbersome to create and if you have suggestions about how to improve this process
while keeping the flexibility of Inferno to run with any app, submit a ticket 
[here](https://github.com/inferno-framework/davinci-pas-test-kit/issues).

## Limitations

The DTR IG is a complex specification and these tests currently validate conformance to only
a subset of IG requirements. Future versions of the test suite will test further
features. A few specific features of interest are listed below.

### Launching and security

This test kit contains basic SMART App Launch cabilities that may not be complete. In particular,
refresh tokens are not currently supported and scopes are not precise. To provide feedback and 
input on the design of this feature and help us priortize improvements, submit a ticket 
[here](https://github.com/inferno-framework/davinci-pas-test-kit/issues).

### Combined payer and EHR FHIR servers

At this time, the test suite simulates a single FHIR server that uses the same access token
for both the payer server and the EHR server. Apps under test must use the FHIR server base url
and access token identified during the SMART App Launch sequence when making requests
to retrieve questionnaires.

### Questionnaire Feature Coverage

Not all questionnaire features that are must support within the DTR IG are currently represented
in questionnaires tested by the IG. Adaptive questionnaires are a notable omission.
Additional questionnaires testing additional features will be added in the future.
