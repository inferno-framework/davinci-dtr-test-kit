# Controlling DTR Client Requests

During the DTR payer tests, payer systems are asked to demonstrate
that they can respond to requests for Questionnaires. Inferno does not know
and seeks to avoid making assumptions about the configuration and business logic
that determines whether a request will return a Questionnaire or not. Therefore,
Inferno requires testers to provide requests for Inferno to use, either by
manually inputting JSON or using a DTR client to send DTR requests to Inferno.
The **DTR Request Mode** input toggles between these two options.

## DTR Request Modes

### Manual Mode

In Manual mode, testers input JSON which Inferno uses to construct DTR requests.
This is the default mode.

#### $questionnaire-package Requests

In Manual mode, testers provide the verbatim `$questionnaire-package` request
body for Inferno to use when making the requests. The specific input will
specify whether multiple requests can be provided or not.

#### $next-question Requests

When completing adaptive Questionnaires, DTR clients iteratively make requests
in the form of a QuestionnaireResponse with a contained Questionnaire and receive
back the same with either additional questions added to the the contained Questionnaire
or an indication that the QuestionnaireResponse is now complete. In this way,
both the responses and the subsequent request are designed to be reactions to the preceding
response or request.

In Manual mode, rather than specify a sequence of requests for Inferno to make that may or
may not match the preceding response, Inferno asks testers to specify, for each
adaptive Questionnaire that the simulated DTR client may receive from the payer,
the end state in the form of a QuestionnaireResponse template with questions
answered.

For each adaptive Questionnaire returned from a $questionnaire-package request, Inferno will
identify the template to use using the Questionnaire's canonical URL. It will
make an initial $next-question request using the with QuestionnaireResponse
from the $questionnaire-package response. Inferno will then construct
subsequent $next-question request bodies by adding responses to the QuestionnaireResponse from
the identified template. Inferno will make $next-question requests until either
1. A non-successful response is returned by the payer, or
2. The payer indicates that the QuestionnaireResponse is completed, or
3. No new questions were added by the payer, or
4. The template had no answers to add based on the new questions added.

#### ValueSet/$expand Requests

In Manual mode, Inferno sends a `ValueSet/$expand` request for each ValueSet in
a `$questionnaire-package` response that has a canonical URL but no expansion.
The request is a Parameters resource containing that canonical URL.

#### Current Limitations

At this time, only a single template may be provided for each Questionnaire canonical url
(first one in the list will be used), meaning that Inferno can only fill out each
Questionnaire one way. In the future, additional selection criteria may be added that allows
the template to be chosen based on the contents of the $questionnaire-package request.


### Client Mode

In Client mode, a tester-controlled DTR client sends requests to Inferno while
the **Request Questionnaires** test is waiting. Inferno forwards each request to
the payer server under test and returns the payer's response to the client. This
allows the client to execute a workflow, such as completing an adaptive
Questionnaire, using the payer's actual responses.

To use Client mode:

1. Select **Client mode** for **DTR Request Mode** and provide a **DTR Client
   Access Token**.
2. Run the **Request Questionnaires** test. Its waiting message lists the
   Inferno URLs for the supported operations.
3. Have the DTR client send requests to those URLs with
   `Authorization: Bearer <DTR Client Access Token>` on every request.
4. When the client workflow is complete, use the resume link in the waiting
   message to complete the test.

Client mode supports `Questionnaire/$questionnaire-package`,
`Questionnaire/$next-question`, and `ValueSet/$expand`. Inferno forwards the
received request body to the payer and records the request sent to the payer for
use by subsequent tests. The payer request uses the suite's Backend Services
Credentials and `Content-Type: application/fhir+json`. Inferno returns the
payer's response status, body, and `Content-Type` header to the DTR client.
Inferno does not forward other request or response headers.

## Error Handling

DTR Request Mode controls only the **Request Questionnaires** test. The
separate **Error Handling** group has Inferno make its own error-case requests,
regardless of the selected mode. It requires tester-provided request bodies for
an unresolvable-source-data `$questionnaire-package` request and an invalid
`QuestionnaireResponse` for `$next-question`. These inputs remain available
when using Client mode, because a DTR client may not be able to produce the
required invalid requests.

The group also adds an unknown Questionnaire to a previously recorded
`$questionnaire-package` request. Therefore, this test requires at least one
prior `$questionnaire-package` request in either Manual or Client mode.
