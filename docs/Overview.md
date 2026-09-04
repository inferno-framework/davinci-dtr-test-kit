# Da Vinci DTR Test Kit Overview

The **Da Vinci Documentation Templates and Rules (DTR) Test Kit** is a testing tool designed
to validate the conformance of DTR client and server systems to versions of the
Da Vinci Documentation Templates and Rules (DTR) FHIR Implementation Guide (IG), including
- [Da Vinci Documentation Templates and Rules (DTR) STU 2.0.1](https://hl7.org/fhir/us/davinci-dtr/STU2), and
- [Da Vinci Documentation Templates and Rules (DTR) STU 2.2.0](https://hl7.org/fhir/us/davinci-dtr/2.2.0)

This document provides a high-level overview of the Test Kit, including its purpose, general testing
approach, scope, limitations, and guidance on how to interpret results.

## Purpose

This test kit helps implementers ensure that their systems can correctly participate in
Qustionnaire retrieval and completion workflows as defined by the DTR IG. It does so by simulating
an exchange partner for the system under test (when testing a DTR client Inferno will simulate
a DTR server and vice-versa) and verifying that each exchange is conformant and that
all exchanges in aggregate demonstrate the required capabilities.

This test kit is [open source](#license) and freely available for use or
adoption by the health IT community including EHR vendors, payer systems, health app
developers, and testing labs. It is built using the [Inferno
Framework](https://inferno-framework.github.io/). The Inferno Framework is
designed for reuse and aims to make it easier to build test kits for any
FHIR-based data exchange.

## Test Kit Actors and Approach

The DTR specification defines two sides of the basic exchange: a payer side which
provides Questionnaires and a provider side which completes them. The specification
further provides for the provider side to be fulfilled either by
- a single DTR Full EHR actor that retrieves Questionnaires, renders them for users to complete,
  and supplies the data, or
- a combination of a DTR SMART Client responsible for retrieving Questionnaires and rendering them
  for users to complete, plus a DTR Light EHR responsible for providing the data.

For the v2.0.1 version of the DTR specification, this test kit contains suites for all 4 actors.
Starting with the v2.2.0 version of the DTR specification, only two suites are provided for
DTR clients and DTR Payer Services. DTR SMART Apps and Light EHRs that wish to test their
capabilities can team up with each other to complete the client suite.

Inferno's testing approach varies based on the target actor
- When testing DTR clients, Inferno will simulate a DTR payer service and provide Questionnaires
  for the tester to complete using the tested client system. Some of these Questionnaires will
  be specified by Inferno to ensure certain scenarios are tested, while others can be specified
  by the tester. Over the course of completing these Questionnaires, the client system will
  demonstrate all of the required capabilities of DTR form fillers. Some details of these
  requirements will be checked by Inferno while others will be attested to by the tester.
  See the [Client Details](Client-Details.md) page for more information.
- When testing DTR payer services, Inferno will simulate a DTR client by making requests
  to the server's $questionnaire-package and $next-question operations. These requests
  will be provided by the tester so that Inferno's requests will contain the right details
  to trigger responses with Questionnaires. Inferno will ask for requests to make
  that demonstrate the full scope of DTR payer services capabilities. See the
  [Server Details](Server-Details.md) page for more information.

In each case, content provided by the system under test will be checked individually
for conformance and in aggregate to determine that the full set of features 
required by the IG for the actor is supported.

## Test Scope and Limitations

These tests are a **DRAFT** intended to allow DTR implementers to perform
preliminary checks of their implementations against the DTR IG requirements and
provide feedback on the tests. Future versions of these tests may validate other
requirements and may change how these are tested.

While these tests cover core aspects of the DTR IG, there are known limitations:
- DTR workflow are highly visual with significant numbers of requirements around
  the rendering and population of and interaction with Questionnaires by users,
  or the design of such Questionnaires to integrate into workflows where users
  will fill them out. Inferno is not able to rigorously verify these visual
  and design-level requirements related to Questionnaires.
- Logic within Quesitonnaires can be driven by Clinical Quality Language (CQL)
  expressions, which can contain complex logic. Inferno does not include a
  CQL execution engine and so has limited ability to evaluate CQL expressions
  or the answers to them provided by client systems for correctness.

For a details on specific specific limitations, detailed requirements, and known
issues, please consult the following resources: 
- [Client Testing Limitations](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Client-Details#limitations)
- [Server Testing Limitations](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Server-Details#limitations)
- Relevant [requirements](https://inferno-framework.github.io/docs/advanced-test-features/requirements.html):
  - DTR Requirements Spreadsheets
    - [v2.0.1](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/requirements/hl7.fhir.us.davinci-dtr_2.0.1_requirements.xlsx)
    - [v2.2.0](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/requirements/hl7.fhir.us.davinci-dtr_2.2.0_requirements.xlsx)
- [DTR Test Kit GitHub Issues page](https://github.com/inferno-framework/davinci-dtr-test-kit/issues).

## Conformance Criteria & Interpreting Results

A test run is considered successful if all mandatory tests pass:
* **Passing Tests**: Indicate expected behavior for specific scenarios
* **Failing Tests**: Indicate deviations from DTR IG requirements
* **Warnings**: Highlight potential concerns that require manual review
* **Skipped Tests**: Occur when necessary prerequisites are not met
* **Omitted Tests**: Occur when optional prerequisites are not met

Given the [known limitations](#test-scope-and-limitations), passing all automated tests does **not**
solely constitute full DTR IG conformance. Systems should also meet requirements verified through
attestation or other means.

For specific testing prerequisites and detailed test descriptions, refer to:
* [Client v2.2.0 Suite Testing Instructions](Client-Instructions-v2.2.0.md)
* [Server v2.2.0 Suite Testing Instructions](Server-Instructions-v2.2.0.md)
