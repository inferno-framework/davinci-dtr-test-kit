require_relative '../../validation_test'

module DaVinciDTRTestKit
  class DeviceRequestValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest

    title 'DeviceRequest resources returned during previous tests conform to the CRD DeviceRequest'
    description %(
This test verifies resources returned from the first read conform to
the [CRD DeviceRequest](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-devicerequest).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :device_request_validation
    input :device_request_resources

    def resource_type
      'DeviceRequest'
    end

    run do
      perform_request_validation_test(device_request_resources, resource_type,
                                      'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-devicerequest',
                                      '', true)
    end
  end
end