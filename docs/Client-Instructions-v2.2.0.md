# Da Vinci DTR Test Kit: Payer Client v2.2.0 Testing Instructions

## Overview

During the execution of the DTR client suite, Inferno will act as a payer
server making Questionnaires available to the client for it to retrieve
and use to demonstrate their ability to render, populate, and complete Questionnaires.

### Minimum requirements

At minimum to execute the DTR client tests, systems must support 
SMART Backend Services and specifically be able to
1. Provide a JWKS Set used to sign token request JWTs
1. Request an access token using SMART Backend Services
1. Send that access token as a bearer token in the Authorization header
   on DTR requests to Inferno.

### Tester inputs

For some tests, Inferno uses fixed Questionnaires to elicit a demonstration
of specific features in a controlled way. These tests require minimal tester
input and are described in the [_Inferno-provided Questionnaire Tests Exection_](#inferno-provided-questionnaire-tests-execution)
section below. However, demonstration of other features requires testers
to provide their own Questionnaires for Inferno to send to them, which requires
significantly more up-front information from the tester. Execution details for these
tests are described in the  [_Tester-provided Questionnaire Tests Exection_](#tester-provided-questionnaire-tests-execution)
section below. Additionally, see
- **[Controlling Simulated DTR Client Responses](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Controlling-Simulated-Responses)**: 
   provides details on how to provide those details.
- **[Running Suites Against Each Other_ page](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Running-Suites-Against-Each-Other)**:
   contains instructions on how to run the client and server suites against each other.
   Those presets may have additional example Questionnaires that can be used.

## Registration Test Execution

During group "1 Client Registration", the client system will
1. Optionally provide a client id for Inferno use when registering the
   client system. If not provided, Inferno will generate a client id
   for use during the session.
2. Provide the JWKS as a url or raw JSON.

Inferno will then check the JWKS and ask the tester to verify that
the client has been set up to communicate with Inferno's FHIR
server using SMART Backend Services.

## Inferno-provided Questionnaire Tests Execution

Inferno provides fixed Questionnaires to demonstrate two basic workflows that
DTR clients must support:
1. Standard Questionnaires in group 2.1
2. Adaptive Questionnaires in group 2.2

These groups must be executed after the group "1 Client Registration". In each
case, testers don't need to provide any additional inputs up front. Once
they start the test run, Inferno will display a "User Action Required" dialog
asking them to initiate requests for Questionnaires and to tell Inferno when
all Questionnaires have been completed. Once they have done so, Inferno will
ask them to confirm that
1. They were able to render faithfully all features of the returned Questionnaire
   as described in the DTR IG.
2. Each completed Questionnaire has been stored for later use.

Inferno requires this confirmation because it cannot see or evaluate the UI used
to display and interact with the Questionnaire. However, it can and does check
the client's requests and Inferno's simulated responses for conformance to
DTR profiles and requirements.

## Tester-provided Questionnaire Tests Execution

DTR requires support for all Questionnaire features marked as must support within
DTR Questionnaire profiles. However, Inferno's fixed Questionnaires do not include
all of these features. Thus, to demonstrate them, testers must provide additional
Questionnaires with these additional elements and demonstrate their completion.
When executing group "3.1 Additional Questionnaires for Must Support Coverage",
testers have the option to provide these additional Questionnaires to respond with
in the form of `$questionnaire-response` and `$next-question` operation response
templates, which are described in detail on the [_Controlling Simulated DTR Client Responses_ page](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Controlling-Simulated-Responses).
To demonstrate additional Questionnaires, testers will take the following steps
1. Execute group "3.1 Additional Questionnaires for Must Support Coverage", providing
   the response templates in inputs **Additional Must Support $questionnaire-package
   Response Template** and **Additional Must Support $next-question Response Template**.
2. When Inferno displays a "User Action Required" dialog asking them to request
   Questionnaires and complete them, use the client system to trigger requests
   and fill them out. Once all returned Questionnaires are completed, they
   will acknowledge that in Inferno which will continue the tests.
3. When Inferno displays a "User Action Required" dialog asking them to confirm
   that the client system rendered and populated the Questionnaires and allowed
   the tester to complete them, the tester will accurately attest to the result.
4. Inferno will complete the analysis of the interactions, including conformance
   of both client requests and Inferno simulated responses to DTR profile requirements.

## Questionnaire Feature Coverage Test Execution

Regardless of whether additional Questionnaires were completed, group "3.2 Questionnaire
Must Support" can be executed to analyze previously-sent requests and responses
for coverage of all required DTR features. Only interactions performed during the last
execution of a particular group will be considered. This means, e.g., that if you execute
group "3.1 Additional Questionnaires for Must Support Coverage" twice during a session,
only the Questionnaires completed during the second execution will be evaluated.

In particular, Inferno checks for support for all features marked as must support
on DTR Questionnaires, including
- Must support elements defined in the DTR Base Questionnaire profile or one of its parents,
  which can be observed on eitehr Standard or Adaptive Questionnaires.
- Must support elements defined in the DTR Standard or DTR Adaptive Questionnaire profiles,
  which must be observed on the corresponding type of Questionnaire.

Any instance of a feature observered on a Questionnaire returned to the client will be counted
because testers will have confirmed that each returned Questionnaire was completed at least
once and that the must support features within it were rendered or otherwise functioned
as required.

## Authorization Test Execution

After all other tests have been completed, run group "4 Review Authentication Interactions"
so that Inferno can review all authentication interactions performed, including at least
one example of a successful token request for which the token appeared on a subsequent DTR
request. This group requires no additional inputs from the tester either before or during
the tests.
