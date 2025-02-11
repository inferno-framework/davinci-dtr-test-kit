require_relative 'device_request/device_request_read'
require_relative 'device_request/device_request_validation'
require_relative 'device_request/device_request_must_support_test'

module DaVinciDTRTestKit
  class DeviceRequestGroup < Inferno::TestGroup
    title 'CRD DeviceRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD DeviceRequest Profile'
    description %(
      # Background

    The CRD DeviceRequest sequence verifies that the system under test is
    able to provide correct responses for DeviceRequest queries. These queries
    must return resources conforming to the [CRD DeviceRequest Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-devicerequest.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each DeviceRequest resource id provided in
    the DeviceRequest IDs input. The server SHOULD be capable of returning a
    DeviceRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD DeviceRequest Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-devicerequest.html).
    Each element is checked against terminology binding and cardinality requirements.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the DeviceRequest resources found in the first test for these
    elements.

    )
    id :device_request_group
    optional
    run_as_group

    input :device_request_ids,
          title: 'Device Request IDs',
          description: 'Comma separated list of DeviceRequest IDs',
          optional: true

    test from: :device_request_read
    test from: :device_request_validation
    test from: :device_request_must_support_test
  end
end
