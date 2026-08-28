## Test Methodology

Inferno will simulate a DTR client that makes requests for questionnaires and
submits QuestionnaireResponses to the system under test. The server will be
expected to respond to these requests made by Inferno. Over the course of these
interactions, Inferno will seek to observe conformant handling of DTR
[requirements](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#defining-questionnaires)
around standard questionnaires, adaptive questionnaires, or both. Inferno will
then perform the `ValueSet/$expand` operation on ValueSets included in the
returned Questionnaires to verify that the server supports it.

The tests verify that the Questionnaires support pre-population from the EHR,
using logic to only display relevant questions, and can use all Must Support
fields.

Because the business logic that determines which questionnaires are returned
is outside of the DTR specification and will vary between implementers, testers
are required to provide the requests that Inferno will make to the server, either
by providing the requests to make up-front, or by sending them to Inferno during
test execution using a tester-controlled client.

All responses returned by the server, as well as tester-provided requests, will
be checked for conformance to the DTR IG requirements individually and used in
aggregate to determine whether required features and functionality are present.
HL7® FHIR® resources are validated with the Java validator using `tx.fhir.org`
as the terminology server.

## Limitations

These tests currently require the server under test to demonstrate a single
example of a conformant standard (static) and / or an adaptive questionnaire.
This is based on the interpretation of the DTR IG as allowing payers to choose
the features that they want to support. If this interpretation turns out to be
inconsistent with the intention of the IG authors then future versions of the
tests may require the payer to provide additional examples.

The payer responses are also tested to ensure that appropriate libraries and
expressions are included to facilitate pre-population of questionnaires. The
following is not tested:

- CQL is version 1.5
- CQL is valid and executed to populate the questionnaire
- CQL has a context of “Patient”
- CQL definitions and variables defined on ancestor elements or preceding
  expression extensions within the same
  Questionnaire item are in scope for referencing in descendant/following expressions.
- Within Expression elements, the base expression CQL SHALL be accompanied by a
  US Public Health Alternative Expression Extension containing the compiled JSON
  ELM for the expression.
