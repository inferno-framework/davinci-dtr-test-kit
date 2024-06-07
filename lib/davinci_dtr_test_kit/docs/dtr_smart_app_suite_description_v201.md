The Da Vinci DTR Test Kit Smart App Suite validates the conformance of Smart apps
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

Tests within this suite are associated a specific questionnaires that the app will
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
  the prepopulation logic and the data used in calculation) and other conformance details.

Apps will be required to complete all quesitonnaires in the suite, which in aggregate
contain all questionnaire features that apps must support. Currently, the suite includes
two questionnaires:
1. A fictious "dinner" questionnaire created for these tests. It tests basic
   item rendering and pre-population.
2. A Respiratory Assist Device questionnaire pulled from the DTR reference implementation.
   It tests additional features and represents a more realistic questionnaire.
Additional questionnaires will be added in the future.

All reqeusts sent by the app will be checked 
for conformance to the DTR IG requirements individually and used in aggregate to determine
whether required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

Inferno does not currently include the ability to launch the client. Therefore, clients
must be manually configured to point to Inferno's simulated server endpoints. The endpoints
can be infered from the url of the test session which will be of the form `[url prefix]/dtr_smart_app/[session id]`: (NOTE: both currently use the same url)
- Payer Server Base FHIR url: `[url prefix]/custom/dtr_smart_app/fhir`
- Light EHR Base FHIR url: `[url prefix]/custom/dtr_smart_app/fhir`

In order for Inferno to associate requests sent to locations under these base urls with this session,
it needs to know the bearer token that the app will send on requests, for which 
there are two options.

1. If you want to choose your own bearer token, then
    1. Select the "2. Basic Workflows" test from the list on the left (or other target test). 
    2. Click the '*Run All Tests*' button on the right.
    3. In the "access_token" field, enter the bearer token that will be sent by the client 
       under test (as part of the Authorization header - `Bearer <provided value>`).
    4. Click the '*Submit*' button at the bottom of the dialog.
2. If you want to use a client_id to obtain an access token, then
    1. Click the '*Run All Tests*' button on the right.
    2. Provide the client's registered id "client_id" field of the input (NOTE, Inferno doesn't support the
        registration API, so this must be obtained from another system or configured manually).
    3. Click the '*Submit*' button at the bottom of the dialog.
    4. Make a token request that includes the specified client id to the
        `[url prefix]/custom/dtr_smart_app/mock_auth/token` endpoint to get
        an access token to use on the request of the requests.

In either case, the tests will continue from that point. Further executions of tests under
this session will also use the selected bearer token.

Note: authentication options for these tests have not been finalized and are subject to change.

### Postman-based Demo

If you do not have a DTR Smart app but would like to try the tests out, you can use
[this Postman collection](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/config/DTR%20Test%20Kit.postman_collection.json)
to make requests against Inferno. This does not include the capability to render the complete the
questionnaires, but does have samples of correctly and incorrectly completed QuestionnaireResponses.
The following is a list of tests with the Postman requests that can be used with them:

- **2.1** *Static Questionnaire Workflow*: use requests in the `Static Dinner` folder
  - **2.1.1.01** *Invoke the DTR Questionnaire Package operation*: submit request `Questionnaire Package for Dinner (Static)` while this test is waiting.
  - **2.1.3.01** *Save the QuestionnaireResponse after completing it*: submit request `Save QuestionnaireResponse for Dinner (Static)` while this test is waiting. If you want to see a failure, submit request `Save QuestionnaireResponse for Dinner (Static) - missing origin extension` instead.
- **3.1** *Respiratory Assist Device Questionnaire Workflow*: use requests in the `Respiratory Assist Device` folder
  - **3.1.1.01** *Invoke the DTR Questionnaire Package operation*: submit request `Questionnaire Package for Resp Assist Device` while this test is waiting.
  - **3.1.3.01** *Save the QuestionnaireResponse after completing it*: submit request `Save Questionnaire Response for Resp Assist Device` while this test is waiting. If you want to see a failure, submit request `Save Questionnaire Response for Resp Assist Device - unexpected override` instead.

## Limitations

The DTR IG is a complex specification and these tests currently validate Smart app
configuration to only part of it. Future versions of the test suite will test further
features. A few specific features of interest are listed below.

### Launching and security

The primary limitation on this test suite is that it requires the client under test
to be manually configured to point to the Inferno endpoints and send a bearer token. 
In the future, the tests will provide a mechanism for launching the application using
the Smart app launch mechanism. To provide feedback and input on the design of this feature,
submit a ticket [here](https://github.com/inferno-framework/davinci-pas-test-kit/issues).

### Questionnaire Feature Coverage

Not all questionnaire features that are must support within the DTR IG are currently represented
in questionnaires tested by the IG. Adaptive questionnaires are a notable omission.
Additional questionnaires testing additional features will be added in the future.
