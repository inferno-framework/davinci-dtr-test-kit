# Running the DTR Client and Server Suites Against Each Other

During development and debugging, it can be useful to run the client and server suites
against each other to confirm behavior, design decisions, or bug fixes. The following
instructions can be used to do so. These instructions do not work when running the
test kit locally within Docker due to networking restrictions when running without a
dedicated hostname.

## v2.0.1

Running 2.0.1 suites against each other is not currently supported.

## v2.2.0

NOTE: DTR tests for the v2.2.0 version are currently a work in progress. These
instructions provide a starting point, but are not currently expected to pass.

## Setup and Authentication

1. Start a "Da Vinci DTR Client Test Suite v2.2.0" using the "SMART Backend Services" option.
1. Apply preset "Run Against the Client Simulation Suite"
1. Run client group "1 Registration"
1. Create a "Da Vinci DTR Client Simulator Suite v2.2.0" session in a new tab.
1. Apply preset "Run Against the DTR Client Suite"
1. Run server group "1 Backend Services". Some tests around failure cases will fail, but 
   the successful token exchange test will succeed.
1. Return to the client session and attest that the client has been configured to connect to Inferno.

## Static Questionnaire Tests

1. In the client session, run group "2.1 Static Questionnaire". No inputs need to be adjusted.
   A "User Action Required" dialog will appear asking the tester to request Questionnaires. 
1. Return to the server session and execute group "2 Payer serves Questionnaires".
1. Return to the client session and click the link to indicate that all requests have been made.
   Respond to additional "User Action Required" dialogs that appear asking for attestations.

Request and response evaluation within the client session fail at this time due to known
issues with the requests.

## Adaptive Questionnaire Tests

1. In the client session, run group "2.1 Adaptive Questionnaire". No inputs need to be adjusted.
   A "User Action Required" dialog will appear asking the tester to request Questionnaires. 
1. Return to the server session and execute group "2 Payer serves Questionnaires".
1. Return to the client session and click the link to indicate that all requests have been made.
   Respond to additional "User Action Required" dialogs that appear asking for attestations.

Note that 4 $next-question requests should have been made.
Request and response evaluation within the client session fail at this time due to known
issues with the requests.
