require_relative 'device_request/device_request_read'
require_relative 'device_request/device_request_validation'

module DaVinciDTRTestKit
  class DeviceRequestGroup < Inferno::TestGroup
    title 'CRD DeviceRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD DeviceRequest Profile'
    description %(
      # Background

    The CRD DeviceRequest sequence verifies that the system under test is
    able to provide correct responses for DeviceRequest queries. These queries
    must return resources conforming to the [CRD DeviceRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-devicerequest)
    as specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    This test sequence will first perform the required read associated
    with this resource. The server SHOULD be capable of returning a
    DeviceRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the first read is expected to conform to
    the [CRD DeviceRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-devicerequest).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :device_request_group
    run_as_group

    input :device_request_ids

    test from: :device_request_read
    test from: :device_request_validation
  end
end
