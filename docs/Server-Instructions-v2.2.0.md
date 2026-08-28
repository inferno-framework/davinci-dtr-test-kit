# Da Vinci DTR Test Kit: Payer Server v2.2.0 Testing Instructions

## Overview

Execution of these tests require a significant amount of tester input in the
form of requests that Inferno will make against the system under test. If
you don't have a server or know specific requests that will elicit representative
questionnaires from your server, see the _Sample Execution_ section below.

When running the tests, the tester will need to provide:
1. The base FHIR url of the system under test.
1. SMART Backend Services credentials to allow Inferno to perform authorization
   with the system under test.
1. JSON request bodies for `$questionnaire-package`, and optionally
   `$next-question`. Request bodies must be provided which will cause the system
   under test to return responses which demonstrate support for all behaviors
   required by the IG and all Must Support fields.

In addition to the above configuration needed for identification of tests, the
following additional inputs are required

- _Questionnaire Retrieval Method_: indicate whether only static, only adaptive,
  or both types of questionnaires will be tested.
- _FHIR Server Base Url_: the location of the server to test
- _OAuth Credentials_: if the server under test requires authentication, provide
  those details here.

For more details on additional inputs that may be needed, see the _Additional
Configuration Details_ section below.

### Sample Execution

If you would like to try out the tests but don't have a DTR payer server
implementation, you can run these tests against the DTR SMART Client test suite
included in this test kit using the following steps:

1. Start an Inferno session of the Da Vinci DTR Client Test Suite v2.2.0.
1. Select the _Run against the Payer Server Suite_ option from the Preset
   dropdown in the top left.
1. Select test 2.2 _Adaptive Questionnaire_ from the menu on the left.
1. Click the "Run Tests" button in the upper right.
1. Click the "Submit" button in the dialog that appears.
1. Start an Inferno session of the DTR Payer Server Test Suite v2.2.0.
1. Select the _Run against the DTR Client Suite_ option from the Preset dropdown
   in the top left.
1. Select test 2 _Backend Services_ from the menu on the left.
1. Click the "Run Tests" button in the upper right.
1. Click the "Submit" button in the dialog that appears. The server tests will
   now authorize against the client test session.
1. Select test 3 _Questionnaire Operations_ from the menu on the left.
1. Click the "Run Tests" button in the upper right.
1. Click the "submit" button in the dialog that appears. The server tests will
   now make requests against the client test session, which will respond with
   Questionnaires that the these server tests can validate.
