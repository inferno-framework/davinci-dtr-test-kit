The Da Vinci DTR Test Kit Full EHR Suite validates the conformance of Full EHRs
to the STU 2.2.0 version of the HL7® FHIR®
[Da Vinci Documentation Templates and Rules (DTR) Implementation Guide](https://hl7.org/fhir/us/davinci-dtr/2.2.0/).

## Scope

These tests are a **DRAFT** intended to allow app implementers to perform
preliminary checks of their systems against DTR IG requirements and [provide
feedback](https://github.com/inferno-framework/davinci-dtr-test-kit/issues)
on the tests. Future versions of these tests may validate other
requirements and may change the test validation logic.

## Test Methodology

Inferno will simulate a DTR payer server that will respond to
requests for questionnaires for the EHR under test to interact with.
The EHR will be expected to initiate requests to Inferno to elicit responses. Over the
course of these interactions, Inferno will seek to observe conformant handling of
DTR workflows and requirements around the retrieval and completion of questionnaires
and the storage of questionnaire responses.

Because Inferno sees each QuestionnaireResponse submitted with an adaptive
`$next-question` request, it can also check details of the answers themselves.
For example, the Pre-populated Answers and Answer Origin scenario verifies that
users can change pre-populated answers without being required to, and that the
client records the origin (`auto-client`, `override`, or `manual`) of each answer.