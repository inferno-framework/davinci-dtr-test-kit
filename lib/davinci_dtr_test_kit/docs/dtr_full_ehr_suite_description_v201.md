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

Inferno will simulate a DTR payer server that will response to
requests for questionnaires for the EHR under test to interact with. 
The EHR will be expected to initiate requests to Inferno to elicit responses. Over the
course of these interactions, Inferno will seek to observe conformant handling of 
DTR workflows and requirements around the retrieval, completion, and storage of
questionnaires.

Tests within this suite are associated with specific questionnaires that the EHR will
demonstrate completion of. In each case, the EHR under test will initiate a request to
the payer server simulated by Inferno for a questionnaire using the 
`$questionnaire-package` operation. Inferno will always return the specific questionnaire
for the test being executed regardless of the input provided by the EHR, though it must
be conformant. The EHR will then be asked to complete the questionnaire, including
- Pre-populating answers based on directives in the questionnaire
- Rendering the questionnaire for users and allowing them to make additional updates.
  These tests can include specific directions on details to include in the completed
  questionnaire.
- Storing the completed questionnaire for future use as a FHIR QuestionnaireResponse.

EHRs will be required to complete all questionnaires in the suite, which in aggregate
contain all questionnaire features that apps must support. Currently, the suite includes
one questionnaire:
1. A fictious "dinner" questionnaire created for these tests. It tests basic
   item rendering and pre-population.
Additional questionnaires will be added in the future.

All requests sent by the app will be checked 
for conformance to the DTR IG requirements individually and used in aggregate to determine
whether required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

In order to run these tests, EHRs must be configured to interact with Inferno's simulated
payer server endpoint. The endpoint will be `[URL prefix]/custom/dtr_full_ehr/fhir` where
`[URL prefix]` can be inferred from the URL of the test session which will be of the form 
`[URL prefix]/dtr_full_ehr/[session id]`.

In order for Inferno to associate requests sent to locations under these base URLs with this session,
it needs to know the bearer token that the EHR will send on requests, for which 
there are two options.

1. If you want to choose your own bearer token, then
    1. Select the "2. Basic Workflows" test from the list on the left (or other target test). 
    2. Click the '*Run All Tests*' button on the right.
    3. In the "access_token" field, enter the bearer token that will be sent by the client 
       under test (as part of the Authorization header - `Bearer <provided value>`).
    4. Click the '*Submit*' button at the bottom of the dialog.
2. If you want to use a client_id to obtain an access token, then
    1. Click the '*Run All Tests*' button on the right.
    2. Provide the EHR's registered id "client_id" field of the input (NOTE, Inferno 
       doesn't support the registration API, so this must be obtained from another
       system or configured manually).
    3. Click the '*Submit*' button at the bottom of the dialog.
    4. Make a token request that includes the specified client id to the
        `[URL prefix]/custom/dtr_full_ehr/mock_auth/token` endpoint to get
        an access token to use on the request of the requests.

In either case, the tests will continue from that point. Further executions of tests under
this session will also use the selected bearer token.

Note: authentication options for these tests have not been finalized and are subject to change.

### Postman-based Demo

If you do not have a DTR Full EHR but would like to try the tests out, you can use
[this Postman collection](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/config/DTR%20Full%20EHR%20Tests%20Postman%20Demo.postman_collection.json)
to make requests against Inferno. This does not include the capability to render and complete the
questionnaires, but does have samples of correctly and incorrectly completed QuestionnaireResponses.
To run the tests using this approach:

1. Install [postman](https://www.postman.com/downloads/).
1. Import [this Postman collection](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/config/DTR%20Full%20EHR%20Tests%20Postman%20Demo.postman_collection.json).
1. Start a Da Vinci DTR Full EHR Test Suite Session.
1. Update the postman collection configuration variables found by opening the "DTR Full EHR
   Tests Postman Demo" collection and selecting the "Variables" tab.
   - **base_url**: corresponds to the where the test suite session is running. Defaults to 
   `inferno.healthit.gov`. If running in another location, see guidance on the "Overview" tab
   of the postman collection.
   - **access_token**: note the "Current value" (update if desired) for use later.
1. Return to Inferno and in the test list at the left, select *2 Static Questionnaire Workflow*.
1. Click the "Run All Tests" button in the upper right.
1. Add the **access_token** configured in postman to the Inferno input with the same name
1. Click the "Submit" button in Inferno.
1. Attest that the EHR has launched its DTR workflow in Inferno by clicking the link for the **true** response.
1. Once the next wait dialog has appeared within Inferno asking for a `$questionnaire-package` 
   request, use postman to submit the "Questionnaire Package for Dinner (Static)" request. Confirm
   that the response that looks similar to the "Example Working Response" in postman
   and click the link to continue the tests.
1. Attest to the remainder of the tests as desired to get a sense for what is involved in testing
   with an actual EHR implementation. To see what a valid QuestionnaireResponse looks like, see
   the "Sample QuestionnaireResponse for Dinner (Static) ..." request in postman.

## Limitations

The DTR IG is a complex specification and these tests currently validate conformance to only
a subset of IG requirements. Future versions of the test suite will test further
features. A few specific features of interest are listed below.

### Heavy Reliance on Attestations

Currently, these test kits do not have access to the QuestionnaireResponse and so validation
that the EHR performed CQL calculations and generated a conformant QuestionnaireResponse
based on pre-population and manual answers is left to a user attestation rather than a
mechanical check. Some level of mechanical checks are expected to be added in the future.

### Questionnaire Feature Coverage

Not all questionnaire features that are must support within the DTR IG are currently represented
in questionnaires tested by the IG. Adaptive questionnaires are a notable omission.
Additional questionnaires testing additional features will be added in the future.
