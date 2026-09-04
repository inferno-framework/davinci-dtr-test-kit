Note: most of this page describes the v2.2.0 DTR client tests. For
information on the v2.0.1 tests, see the [_DTR v2.0.1 Client Tests_](#dtr-v201-client-tests)
section below.

## Test Methodology

To test DTR clients, Inferno will simulate a DTR payer server that makes
Questionnaires available for the client to complete. The client will be
expected to request Questionnaires, render them, populate them automatically
and through user iteraction, and complete them. Over the course of these
interactions, Inferno will seek to observe conformant handling of DTR
[requirements](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#defining-questionnaires)
around standard questionnaires and adaptive questionnaires, including all
Questionnaire features marked as must support, and the FHIR operations
used to retrieve the Questionnaires and relevant information.

Inferno does not implement payer business logic to determine based on patient
coverage and request details which Questionnaire to respond with. Instead,
depending on the group and what requirements are being exercise, Inferno will
- Always return a fixed Questionnaire, regardless of the details in the request, or
- Return Questionnaires provided by testers, potentially filtered by details
  in the request using tester-provided logic (see the [_Controlling Simulated DTR Client Responses_ page](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Controlling-Simulated-Responses)
  for details on how to specify these response and their filters).

All requests made by the client, as well as Inferno's simulated responses, will
be checked for conformance to the DTR IG requirements individually and used in
aggregate to determine whether required features and functionality are present.
HL7® FHIR® resources are validated with the Java validator using `tx.fhir.org`
as the terminology server.

## Limitations

- **High Dependence of Visual Attestation**: Because DTR involves a significant
  visual component, Inferno relies heavily on the tester to manually validate
  that the client correctly displayed and supported Questionnaire details and
  features.
- **Limited Requirement Coverage**: The tests are not yet fully robust
  and do not cover the full set of DTR client requirements. Future updates
  will increase the coverage, though some areas, like robust CQL execution
  correctness and feature coverage, are likely to remain out of scope.
- **Questionnaire Features**: Inferno's does not include examples of all must support
  Questionnaire features, meaning that testers must provide some of them to pass
  these tests. In the future, Inferno may provide examples for an expanded set of
  features for those testers who don't want to bring their own examples.

## DTR v2.0.1 Client Tests

The DTR Test Kit includes several suites that test provider-side actors against
requirements from the v2.0.1 version of the DTR IG, including
- Da Vinci DTR SMART App Test Suite v2.0.1,
- Da Vinci DTR Full EHR Test Suite v2.0.1, and 
- Da Vinci DTR Light EHR Test Suite v2.0.1.

Due to the complexity of the DTR spec and the lack of robust implementations to
test against during development, these tests remain immature compared to the
v2.2.0 versions and are not currently being actively enhanced.