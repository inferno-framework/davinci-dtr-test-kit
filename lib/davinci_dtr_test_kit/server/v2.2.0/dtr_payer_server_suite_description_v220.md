The Da Vinci DTR Test Kit Payer Server Suite validates the conformance of payer
server systems to the STU 2.2.0 version of the HL7® FHIR® [Da Vinci
Documentation Templates and Rules (DTR) Implementation
Guide](https://hl7.org/fhir/us/davinci-dtr/2.2.0/).

These tests are a **DRAFT** intended to allow payer implementers to perform
preliminary checks of their systems against DTR IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

The best place to get started is the [Server Testing
Instructions](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Server-Instructions-v2.2.0),
which provides a step-by-step guide for running the tests. Visit the [Server
Testing
Details](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Server-Details)
documentation for information about technical implementation and known
limitations of these tests.

Inferno will simulate a DTR client and make a series of requests to the system
under test. Because the business logic that determines Questionnaire design and
which Questionnaires will be returned is outside of the scope of the DTR
specification and will vary between implementers, testers are required to
provide the requests that Inferno will make to the server. These requests must
cause the server to return Questionnaires which demonstrate support for DTR
requirements, including
- Advertising support for DTR operations in the CapabilityStatement
- Support for SMART backend services authorization
- Responding to the `$questionnaire-package`, `$next-question` (optional),
  `ValueSet/$expand`, and `$log-questionnaire-errors` operations
- Populating all Must Support elements in the responses
- Correctly handling errors

All requests and responses will be checked for conformance to the DTR IG
requirements individually and used in aggregate to determine whether required
features and functionality are present. HL7® FHIR® resources are validated with
the Java validator using tx.fhir.org as the terminology server.
