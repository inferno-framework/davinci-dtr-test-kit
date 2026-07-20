# Controlling Responses from Inferno's Simulated DTR Payer Server

During the DTR client tests, provider systems are asked to demonstrate
that they can handle and complete Questionnaires meeting certain requirements.
The Inferno tests provide a some custom-build Questionnaires that testers
must demonstrate that their systems can handle. However, they do not meet
all requirements; for example, they do not contain all must support Questionnaire
elements, which clients are requirement to demonstrate support for.
In order to demonstrate these additional requirements, Inferno requires testers
to provide additional Quesitonnaires for Inferno to use in its responses. This page
describes how testers specify and control Inferno's resposnes.

NOTE: no current tests in the DTR Client v2.2.0 test suite use this functionality.

## $questionnaire-package

Tests for which Inferno's simulated DTR payer server is active specify a Parameters
resource instance via file or input id which is used to create the response.
Tokens of the form `{{<fhirpath>}}` are replaced with the results of the contents
executed against the request Parameters resource, allowing the response to vary
based on the request. To simulate error responses, an OperationOutcome body
may be provided instead.

## $next-question

Tests for which Inferno's simulated DTR payer server is active and is expected
to respond to $next-question requests specify a Questionnaire resource template
instance via file or input id which is used to create the responses. The template
contains question as `item` entries which may also have inclusion criteria. When
Inferno receives a $next-qustion request, it will determing which `item` entries
to add to the contained Questionnaire when building the response by looking at
each `item` in the template that is not already in the Questionnaire provided
in the request and include it if
1. Its parent is present or added, and
2. It has no inclusion criteria or the inclusion criteria are met when evaluated
   against the QuestionnaireResponse from the request.

Note that `item` entries are never taken away during this process.

Additionally, when adding the item to the response,
- Inclusion criteria extensions will be stripped before returning the response
- Tokens of the form `{{<fhirpath>}}` are replaced with the results of the contents
executed against the QuestionnaireResponse from the request.

### Inclusion Criteria

Inclusion criteria extension options include:
- `urn:inferno:dtr:inclusion-criteria`: element `valueExpression.expression` contains
  a FHIRPath expression executed against the QuestionnaireResponse from the request.
  To determine inclusion, the FHIRPath result is interpreted as a boolean where
  - empty collections, collections with multiple entries, and collections with a single `false`
    value are interepreted as `false`.
  - all other collections interpreted as `true`.
- `urn:inferno:dtr:request-range`: element `valueString` contains a single or comma-separated
  list of 1-indexed request numbers or ranges indicaing the requests that the item can first
  be included the response. For example, "1,3-5" would mean that the item would be added on
  request 1, 3, 4, or 5 if its parent were already present or also added.

If multiple criteria are included, all must be met for the item to be included. Recall that if
the item is nested under another item, its parent must already present or added for the child
to be evaluated for inclusion.