The Da Vinci DTR Test Kit Payer Server Suite validates the conformance of payer server
systems to the STU 2 version of the HL7® FHIR®
[Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/STU2/).

## Scope

These tests are a **DRAFT** intended to allow payer implementers to perform
preliminary checks of their systems against PDex IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a DTR client application (SMART client or Full EHR) that
is making requests for questionnaires for the server under test to interact with. 
The server will be expected to respond to these requests made by Inferno. Over the
course of these interactions, Inferno will seek to observe conformant handling of 
DTR [requirements](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#defining-questionnaires) 
around standard questionnaires, adaptive questionnaires, or both. 

In terms of the validation performed on the returned questionnaires these
tests assume that payers are not required to support specific features, but only those
that they need in order to implement their forms. The DTR IG does [require that](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#population) 
"Questionnaires SHALL include logic that supports population from the EHR where possible"
and puts some restrictions on how Questionnaire features can be used. Thus, these
tests require demonstration of pre-population features and validates conformant
use of Questionnaire features, but don't currently require demonstration of all
Questionnnaire Must Support elements.

Because the business logic that determines which questionnaires are returned
is outside of the DTR specification and will vary between implementers, testers
are required to provide the requests that Inferno will make to the server, either
by providing the requests to make up-front, or by sending them to Inferno during
test execution using a tester-controlled client.

All responses returned by the server, as well as tester-provided requests, will be checked 
for conformance to the DTR IG requirements individually and used in aggregate to determine
whether required features and functionality are present. HL7® FHIR® resources are
validated with the Java validator using `tx.fhir.org` as the terminology server.

## Running the Tests

### Quick Start

Execution of these tests require a significant amount of tester input in the
form of requests that Inferno will make against the server under test. If
you don't have a server or know specific requests that will elicit representative
questionnaires from your server, see the *Sample Execution* section below.

Otherwise, the requests for Inferno to make can be provided in one of two ways:
1. Statically within the Inferno inputs: provide the json request bodies when running
   the tests. This approach works very well for testing standard (static) questionnaires
   where there is only one request for Inferno to make (input = *Initial Static Questionnaire Request*). It is less ideal for adaptive
   questionnaires as a sequence of `$next-question` requests (inputs = *Initial Adaptive Questionnaire Request* and *Next Question Requests*) is required, which is provided as a json list of
   request body objects.
2. Dynamically during test execution: use a tester-controlled client to provide requests to
   Inferno while the tests are running. At points that Inferno needs to make a request, execution
   will pause while the request is provided from the client. Inferno uses a bearer token
   provided in the test inputs (input = *Access Token* for the DTR Client Flow (not the
   one under the *OAuth Credentials* input)) to identify these requests. The provided token 
   must be sent as a part of the string `Bearer <token>` within the `Authentication` header of
   all requests. When Inferno receives a request from the tester-controlled client, it will 
   send that to the server under test and then return the response back to the client so that
   the client's workflow, e.g., around an adaptive questionnaire can continue.

In addition to the above configuration needed for identification of tests, the following additional
inputs are required
- *Questionnaire Retrieval Method*: indicate whether only static, only adaptive, or both types
  of questionnaires will be tested.
- *FHIR Server Base Url*: the location of the server to test
- *OAuth Credentials*: if the server under test requires authentication, provide those details
  here.

For more details on additional inputs that may be needed, see the *Additional Configuration Details*
section below.

### Sample Execution

If you would like to try out the tests but don't have a DTR payer server implementation,
you can run these tests against the DTR SMART Client test suite included in this test kit
using the following steps:
1. Start an Inferno session of the Da Vinci DTR Smart App Test Suite.
1. Select test 2.1.1 *Static Questionnaire Workflow* from the menu on the left.
1. Click the "Run All Tests" button in the upper right.
1. In the "access_token" input, put `cnVuIHRvZ2V0aGVy`.
1. Click the "submit" button in the dialog that appears. The client tests will now be waiting for requests.
1. Start an Inferno session of the DTR Payer Server test suite.
1. Select test 1 *Static Questionnaire Package Retrieval* from the menu on the left.
1. Select the *Run Against DTR Smart App Tests* option from the Preset dropdown in the
   upper left.
1. Click the "Run All Tests" button in the upper right.
1. Click the "submit" button in the dialog that appears. The server tests will now make requests
   against the client test session, which will respond with a static questionnaire that the 
   these server tests can validate.

At this time, only the standard questionnaire functionality can be tested using this approach as
the client tests have not implemented a adaptive questionnaire set of tests.

## Additional Configuration Details

The details provided here supplement the documentation of individual fields in the input dialog
that appears when initiating a test run.

### Custom Endpoint for Accessing a Particular Resource

If the `$questionnaire-package` requests should be made to a location other than 
`/Questionnaire/$questionnaire-package` under the base server url, enter the
location the requests should be made relative to the base server url.

## Limitations

These tests currently require the server under test to demonstrate a single example of
a conformant standard (static) and / or an adaptive questionnaire. This is based
on the interpretation of the DTR IG as allowing payers to choose the features that
they want to support. If this interpretation turns out to be inconsistent with the
intention of the IG authors then future versions of the tests may require the payer
to provide additional examples.

The payer responses are also tested to ensure that appropriate libraries and expressions are
 included to faciliate pre-population of questionnaires. The following is not tested:
- CQL is version 1.5
- CQL is valid and executed to populate the questionnaire
- CQL has a context of “Patient”
- CQL definitions and variables defined on ancestor elements or preceding expression extensions within the same
Questionnaire item are in scope for referencing in descendant/following expressions.
- Within Expression elements, the base expression CQL SHALL be accompanied by a US Public Health Alternative Expression Extension containing the compiled JSON ELM for the expression.