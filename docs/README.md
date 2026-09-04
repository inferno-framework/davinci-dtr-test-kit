# Da Vinci DTR Test Kit Documentation

The **Da Vinci Documentation Templates and Rules (DTR) Test Kit** is a testing tool
that is designed to help implementers validate systems against the 
HL7® FHIR® [Da Vinci Documentation Templates and Rules Implementation
Guide](https://hl7.org/fhir/us/davinci-dtr/). Currently, it includes
suites that verify the behavior of DTR systems against the following
versions of the DTR IG
- [Da Vinci Documentation Templates and Rules (DTR) v2.0.1](https://hl7.org/fhir/us/davinci-dtr/STU2)
- [Da Vinci Documentation Templates and Rules (DTR) v2.2.0](https://hl7.org/fhir/us/davinci-dtr/2.2.0)

The following documentation provides information on how to use and contribute
to this test kit.

## Using this Test Kit

*   **[Getting Started](https://github.com/inferno-framework/davinci-dtr-test-kit/tree/main/README.md#how-to-run)**: Instructions on how to set up and run the test kit.
*   **[Test Kit Overview](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Overview)**: (TODO) A detailed explanation of what the test kit does, its scope, and how its tests are structured.

### Using the Da Vinci DTR Client Test Suites
*   **[Client Testing Details](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Client-Details)**: Description of the client tests.
*   **Client Testing Instructions**: Step-by-step guide for testing client systems against the [v2.2.0 version](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Client-Instructions-v2.2.0).
*   **[Controlling Simulated DTR Server Responses](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Controlling-Simulated-Responses)**: Details on how testers can control the responses returned by Inferno's simulated DTR server during client testing.

### Using the Da Vinci DTR Server Test Suites 
*   **[Server Testing Details](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Server-Details)**: Description of the server tests.
*   **Server Testing Instructions**: Step-by-step guide for testing server systems against the [v2.2.0 version](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Server-Instructions-v2.2.0).
*   **[Controlling Simulated DTR Client Requests](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Controlling-Simulated-Requests)**: Details on how testers can control the requests made by Inferno's simulated DTR client during payer server testing.

## Contributing to this Test Kit

*   **[Running the Client and Server Suites Against Each Other](https://github.com/inferno-framework/davinci-dtr-test-kit/wiki/Running-Suites-Against-Each-Other)**:
     Step-by-step guide for using the client and server suites to demonstrate the test execution without a separate DTR
    implementation, which can be useful for learning as well as debugging.

## Reference Documents

*   **DTR Requirements Spreadsheets**: Spreadsheets detailing the interpretation of DTR IG requirements for this test kit:
    [v2.0.1](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/requirements/hl7.fhir.us.davinci-dtr_2.0.1_requirements.xlsx)
    and [v2.2.0](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/requirements/hl7.fhir.us.davinci-dtr_2.2.0_requirements.xlsx).

## Support

If you have any problems, please open an issue on our [GitHub Issues page](https://github.com/inferno-framework/davinci-dtr-test-kit/issues).
