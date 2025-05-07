The Da Vinci DTR Test Kit Full EHR Suite validates the conformance of Full EHRs
to the STU 2 version of the HL7® FHIR®
[Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

## Scope

These tests are a **DRAFT** intended to allow app implementers to perform
preliminary checks of their systems against DTR IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a DTR payer server that will respond to
requests for questionnaires for the EHR under test to interact with.
The EHR will be expected to initiate requests to Inferno to elicit responses. Over the
course of these interactions, Inferno will seek to observe conformant handling of
DTR workflows and requirements around the retrieval and completion of questionnaires
and the storage of questionnaire responses.

The suite includes two types of tests each with a different source for the response(s)
that Inferno's simulated payer will return:
- **Tester-provided Responses**: The tester provides a conformant `$questionnaire-package` response,
  and `$next-question` responses for adaptive questionnaires, that Inferno will echo
  back to the system under test. This allows the tester to demonstrate the DTR
  functionality of the system using questionnaires that they choose.
- **Inferno-provided Reponses**: This test suite includes several mocked questionnaires
  that will be returned when specific tests are run.

Regardless of the type, the EHR under test will initiate a request to
the payer server simulated by Inferno for a questionnaire using the
`$questionnaire-package` operation and Inferno will return the responses based on the type of test.
Inferno always returns that specific response associated with the test, whether based on a tester
input or the Inferno responses associated with that test. The request made by the EHR must be conformant,
but Inferno is not able to verify that its response is appropriate for the request. 

The EHR will then be asked to complete the questionnaire, including:

- Pre-populating answers based on directives in the questionnaire.
- Rendering the questionnaire for users and allowing them to make additional updates.
  Tests for Inferno-provided responses include specific directions on details to include in the completed
  questionnaire to allow for validation of the [information origin extension](https://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-information-origin.html).
- For adaptive questionnaires only, getting additional questions using the `$next-question`
  operation until the questionnaire is complete.
- Storing the completed questionnaire for future use as a FHIR QuestionnaireResponse.

EHRs are currently required to complete 5 questionnaires as a part of these tests, though
future iterations of this test kit may change this set:
- Tester-provided static and dynamic questionnaires, for workflow demonstration.
- Inferno-provided static and dynamic questionnaires, for demonstration of [information origin 
  extension](https://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-information-origin.html)
  requirements.
- A feature-complete tester-provided static questionnaire, for demonstration of all
  questionnaire features.

All requests sent by the EHR will be checked
for conformance to the DTR IG requirements individually and used in aggregate to determine
whether required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

Inferno's simulated payer endpoints require authentication using the OAuth flows
conforming either to the
- SMART Backend Services flow, or
- UDAP Business-to-Business Client Credentials flow

When creating a test session, select the Client Security Type corresponding to an
authentication approach supported by the EHR. Then start by running the Client Registration
group which will guide you through the registration process. 
See the *Auth Configuration Details* section below for details.

Once registration is complete, execute the Dinner Order Static Questionnaire Workflow tests
using the following steps:
1. Select group **3.1.1** Retrieving the Static Questionnaire from the list on the left, click
   "RUN TESTS" in the upper right, and click "SUBMIT" in the input dialog that appears.
1. A "User Action Required" dialog will appear asking for DTR to be launched for a patient
   meeting specific criteria. Once you have launched DTR from the EHR, click one of the
   attestation links to continue the tests. NOTE: Inferno will not respond to `$questionnaire-package`
   requests during this step.
1. A new "User Action Required" dialog will appear directing you to make a `$questionnaire-package`
   request. Take actions in the EHR to trigger this request. Before beginning to fill out the
   questionnaire, click the link in the dialog to continue the tests.
1. Select group **3.1.2** Filling Out the Static Questionnaire from the list on the left. A series
   of "User Action Required" dialogs will appear asking you to confirm details of the rendered
   questionnaire and actions taken while filling it out. Refer to and complete these attestations
   as you fill out the questionnaire within the EHR.
1. Complete the questionnaire, save the response in the EHR, and access the saved response in
   its FHIR QuestionnaireResponse JSON form, which will be needed in the next step.
1. Select group **3.1.3** Saving the QuestionnaireResponse from the list on the left and click
   "RUN TESTS" in the upper right. An input dialog will appear asking for the 
   **Completed QuestionnaireResponse**. Put the FHIR QuestionnaireResponse JSON obtained
   in the last step and click "SUBMIT".
1. Attest that this QuestionnaireResponse was stored in the EHR to complete the tests.

Other workflows can be executed in a similar manner, but will include additional inputs and/or
different steps.

### Postman-based Demo

If you do not have a DTR Full EHR but would like to try the tests out, you can use
[this Postman collection](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/config/DTR%20Full%20EHR%20Tests%20Postman%20Demo.postman_collection.json)
to make requests against Inferno. This does not include the capability to render and complete the
questionnaires, but does have samples of correctly and incorrectly completed QuestionnaireResponses.
To run the tests using this approach:

#### Setup
1. Install [postman](https://www.postman.com/downloads/).
1. Import [this Postman collection](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/config/DTR%20Full%20EHR%20Tests%20Postman%20Demo.postman_collection.json).

#### Startup and Client Registration
1. Start a Da Vinci DTR Full EHR Test suite session choosing SMART Backend Services for the Client Security Type.
1. Select the "Dinner Order Questionnaire Example (Postman)" preset from the dropdown in the upper left.
1. Select the Client Registration group from the list at the left, click "RUN TEST" in the upper right,
   and click "SUBMIT" in the input dialog that appears. A "User Action Required" wait dialog will appear.
1. In another tab, start a SMART App Launch STU2.2 suite session. Select the Backend Services group,
   click "RUN TESTS", and provide the following inputs before clicking "SUBMIT":
   - **FHIR Endpoint**: the "FHIR Base URL" displayed in the wait dialog in the DTR tests.
   - **Scopes**: `system/*.rs`
   - **Client ID**: the "SMART Client Id" displayed in the wait dialog in the DTR tests.
1. Find the access token to use for the data access request by opening test **3.2.05** Authorization
   request succeeds when supplied correct information, click on the "REQUESTS" tab, clicking on the "DETAILS"
   button, and expanding the "Response Body". Copy the "access_token" value, which will be a ~100 character
   string of letters and numbers (e.g., eyJjbGllbnRfaWQiOiJzbWFydF9jbGllbnRfdGVzdF9kZW1vIiwiZXhwaXJhdGlvbiI6MTc0MzUxNDk4Mywibm9uY2UiOiJlZDI5MWIwNmZhMTE4OTc4In0)
1. Update the postman collection configuration variables found by opening the "DTR Full EHR
   Tests Postman Demo" collection and selecting the "Variables" tab.
   - **base_url**: corresponds to the where the test suite session is running. Defaults to
     `inferno.healthit.gov`. If running on another server, see guidance on the "Overview" tab
     of the postman collection.
   - **access_token**: the access token extracted in the previous step.
1. Confirm that registration is complete by clicking the link in the DTR tests to complete the registration tests.

##### UDAP Alternative

To demonstrate the use of UDAP authentication for the DTR EHR, perform the above startup steps with the following changes
- In step 1 when starting the DTR Full EHR test suite session, choose UDAP B2B Client Credentials for the Client Security Type.
- In step 4, start a UDAP Security test suite session instead. Select the "Demo: Run Against the UDAP Security Client Suite"
  preset, then choose the UDAP Client Credentials Flow group, click "RUN TESTS", and update the following inputs before clicking "SUBMIT":
  - **FHIR Server Base URL**: change to the FHIR server indicated in the wait dialog in the DTR tests.
- In step 5, the access token (same format as described above) can be found in test **2.3.01** OAuth token exchange request succeeds when supplied correct information.
- In step 7, there will be two attestations to complete.

All other steps below will be the same.

#### Dinner Questionnaire (Standard)

For the standard (static) questionnaire demo, use the requests in the _Static Dinner_ folder in the 
Postman collection. Follow the quick start instructions above with the following modifications:
- Use postman to submit the "Questionnaire Package for Dinner (Static)" request when Inferno
  is waiting for a `$questionnaire-package` request. Note that the response that looks similar
  to the "Example Working Response" in postman.
- Copy the contents of the "Sample QuestionnaireResponse for Dinner (Static) ..." postman request,
  replace the string `{{base_url}}` with the value of the **base_url** postman variable, and enter the result
  as the **Completed QuestionnaireResponse** input in Inferno.

The "Dinner Order Questionnaire Example (Postman)" preset also populates the same questionnaire as the
tester-provided questionnaire to use in the Basic Workflows -> Static Questionnaire Workflow group. You
can execute that group as well in a similar manner to see how tester-provided questionnaire tests are
different.

These tests are not expected to fully pass due to known issues in the example FHIR instances.

#### Dinner Questionnaire (Adaptive)

For the adaptive questionnaire demo, use the requests in the _Adaptive Dinner_ folder in the 
Postman collection.

1. Return to the Inferno test session and in the test list at the left, select **3.2** Dinner Order Adaptive
   Questionnaire Workflow, click the "RUN ALL TESTS" button in the upper right, and click "SUBMIT" in the input dialog.
1. Attest that the EHR has launched its DTR workflow in Inferno by clicking the link for the **true** response.
1. Once the **Adaptive Questionnaire Retrieval** wait dialog has appeared within Inferno asking 
   for `$questionnaire-package` and `$next-question`
   requests, use postman to submit the "Questionnaire Package for Dinner" request followed by the
   "Initial Next Question" request. Confirm
   that the response that looks similar to the "Example Response" in postman
   and click the link to continue the tests.
1. Attest to the next several attestation wait dialogs as desired to get a sense for what is involved
   in testing with an actual EHR implementation.
1. Once the **Follow-up Next Question Request** wait dialog has appeared within Inferno asking for
   another `$next-question` request, use postman to submit the "Second Next Question" request. Confirm
   that the response that looks similar to the "Example Response" in postman
   and click the link to continue the tests.
1. Once the **Last Next Question Request** wait dialog has appeared within Inferno asking for
   another `$next-question` request, use postman to submit the "Final Next Question" request. Confirm
   that the response that looks similar to the "Example Response" in postman
   and click the link to continue the tests.

The "Dinner Order Questionnaire Example (Postman)" preset also populates the same questionnaire as the
tester-provided questionnaire to use in the Basic Workflows -> Adaptive Questionnaire Workflow group. You
can execute that group as well in a similar manner (note that all `$next-question` requests are made
within a single wait test) to see how tester-provided questionnaire tests are different.

These tests are not expected to fully pass due to known issues in the example FHIR instances.

#### Review Authentication Interactions

Anytime after executing one of the questionnaire test groups, you can execute the Review Authentication Interactions
group to verify the conformance of access token requests against the SMART Backend Services flow.

These tests are not expected to fully pass due to invalid token requests purposefully sent by the SMART server tests.

## Limitations

The DTR IG is a complex specification and these tests currently validate conformance to only
a subset of IG requirements. Future versions of the test suite will test further
features. A few specific features of interest are listed below.

### Questionnaire Response Verification

Currently, these test kits do not have enough information about the data stored on
the EHR to evaluate whether CQL evaluation populated data correctly. However, Inferno
does ask testers to make sure that the target patient meets certain requirements and
directs them to perform certain actions while filling out forms that allow Inferno to
check that calculation is occuring and that the system is correctly keeping track of
items that were pre-populated. This approach may change in future versions of these tests.

### Questionnaire Response Access

For standard (static) questionnaires, Full EHRs are not required by the DTR specification
to store or expose the completed form as a FHIR QuestionnaireResponse instance, though they
are required to store the form in some way and be able to send the QuestionnaireResponse
representation to other systems. Currently, testers are required to provide a
QuestionnaireResponse as an input to the tests once they have completed their workflow.
Future versions of these tests will provide additional options for making that information
available that are more in-line with expected system capabilities.

For adaptive questionnaires, the completed QuestionnaireResponse will be present in the
last `$next-question` invocation by the EHR, so this limitation does not apply to those
cases.
