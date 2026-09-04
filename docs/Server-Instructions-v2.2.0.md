# Da Vinci DTR Test Kit: Payer Server v2.2.0 Testing Instructions

## Overview

Execution of these tests require a significant amount of tester input in the
form of requests that Inferno will make against the system under test. If you
don't have a server or know specific requests that will elicit representative
questionnaires from your server, see the [_Running Suites Against Each Other_
page](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Running-Suites-Against-Each-Other)
for instructions on how to run the client and server suites against each other.

## Test Inputs

When running the tests, the tester will need to provide:
1. The base FHIR url of the system under test.
1. SMART Backend Services credentials to allow Inferno to perform authorization
   with the system under test.
1. JSON request bodies for `$questionnaire-package`, and Questionnaire response
   templates for `$next-question` if the system supports adaptive Questionnaires
   (see see the [_Test Kit Actors and Approach_
   section](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Overview#test-kit-actors-and-approach)
   for more information). Request bodies must be provided which will cause the
   system under test to return responses which demonstrate support for all
   behaviors required by the IG and all Must Support fields.
1. Request bodies for `$questionnaire-package` which include invalid source data
   and an invalid QuestionnaireResponse to validate that the server handles
   these errors correctly.
1. The canonical url of a Questionnaire that the server supports in order to
   test the `$log-questionnaire-errors` operation.
1. If the server's responses include references to resources on the client's
   FHIR server, then the base FHIR url of the client must also be provided.

## Test Execution

Each group can be run in order.

1. The "Discovery" group requests the server's CapabilityStatement and verifies
   that it advertises support for all required DTR functionality.
1. The "Backend Services" group performs SMART on FHIR backend services
   authorization to verify that the server supports it, and to obtain
   authorization for the remaining tests.
1. The "Questionnaire Operations" group contains the majority if the suites
   tests, broken down into sub-groups.
   1. The "Questionnaire Interactions" group performs `$questionnaire-package`,
      `$next-question`, and `ValueSet/$expand` operations and verifies that
      the inputs the user provided for these requests are valid.
   1. The "Questionnaire/$questionnaire-package Support" group verifies that the
      server's responses to `$questionnaire-package` requests are valid.
   1. The "Questionnaire/$next-question Support" group verifies that the
      server's responses to `$next-question` requests are valid.
   1. The "Questionnaire Design" group verifies that the Questionnaires returned
      from both `$questionnaire-package` and `$next-question` meet common
      requirements.
   1. The "ValueSet/$expand Support" group makes expand requests for unexpanded
      ValueSets returned from `$questionnaire-package` and `$next-question`
      requests validates the responses.
   1. The "Error Hanlding" group verifies that the server handles particular
      errors as described in the IG.
   1. The "Must Support" group verifies that the server is capable of populating
      all Must Support fields.
1. The "Log Questionnaire Error Support" group verifies that the server supports
   the `$log-questionnaire-errors` operation.
