## Test Methodology

Inferno will simulate a DTR client that makes requests for questionnaires and
submits QuestionnaireResponses to the system under test. The server will be
expected to respond to these requests made by Inferno. Over the course of these
interactions, Inferno will seek to observe conformant handling of DTR
[requirements](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#defining-questionnaires)
around standard questionnaires, adaptive questionnaires, or both. Inferno will
then perform the `ValueSet/$expand` operation on ValueSets included in the
returned Questionnaires and perform `$log-questionnaire-errors` operations to
verify that the server supports these operations.

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

The tests currently require user input to populate request bodies for all
`$questionnaire-package` and `$next-question` requests that will be made in the
suite. The tests may be updated in the future to allow Inferno to act as a proxy
between the payer server and a DTR client so that the user does not have to
provide these request bodies manually.

Some of the server requirements in the IG are not currently tested by the payer
suite. Below is a list of untested requirements along with reasons they are not
tested.

### Organizational Requirements
These are requirements on the payer organization itself rather than on the
interactions between the payer server and a DTR client.
* [conf-10](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-10)
* [conf-14](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-14)
* [conf-15](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-15)
* [sec-9](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/security.html#ci-c-sec-9)
* [sec-10](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/security.html#ci-c-sec-10)
* [spec-1](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-1)
* [spec-7](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-7)
* [spec-11](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-=1)

### Untestable Requirements
Automated conformance testing using Inferno for the following requirements is
not practical for a variety of reasons, such as depending on interpreting the
semantics of an interaction, or on content that is not machine-readable.
* [conf-9](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-9)
* [conf-12](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-12)
* [conf-13](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-13)
* [oper-7](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-questionnaire-package.html#ci-c-oper-7)
* [oper-8](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-questionnaire-package.html#ci-c-oper-8)
* [sec-3](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/security.html#ci-c-sec-3)
* [sec-4](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/security.html#ci-c-sec-4)
* [spec-6](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-6)
* [spec-21](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-21)
* [spec-22](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-22)
* [spec-38](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-38)
* [spec-41](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-41)
* [spec-42](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-42)
* [spec-43](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-43)
* [spec-45](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-45)
* [spec-120](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-120)
* [spec-128](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-128)
* [spec-159](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-159)
* [spec-165](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-165)

### Not Server Requirements
These requirements are identified as requirements for payer servers, but are
actually requirements for other actors.
* [spec-106](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-106)
* [spec-116](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-116)

### Possibly Tested in the Future
These requirements are not currently tested, but may be tested in future
versions of the payer server suite. Some of these requirements would
significantly expand the scope of of test suite, such as validating CQL content,
or verifying that all security and privacy rules from FHIR Core, HREX, and SMART
App Launch are followed.
* [oper-15](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-questionnaire-package.html#ci-c-oper-15) [[IN PROGRESS](https://github.com/inferno-framework/davinci-dtr-test-kit/pull/121)]
* [sec-1](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/security.html#ci-c-sec-1)
* [spec-92](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-92)
* [spec-93](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-93)
* [spec-94](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-94)
* [spec-97](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-97)
