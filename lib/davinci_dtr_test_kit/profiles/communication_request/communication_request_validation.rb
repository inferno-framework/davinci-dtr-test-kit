require_relative '../../validation_test'

module DaVinciDTRTestKit
  class CommunicationRequestValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest

    title 'CommunicationRequest resources returned during previous tests conform to the CRD CommunicationRequest'
    description %(
This test verifies resources returned from the first read conform to
the [CRD CommunicationRequest](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-communicationrequest).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :communication_request_validation
    input :communication_request_resources

    def resource_type
      'CommunicationRequest'
    end

    run do
      perform_request_validation_test(communication_request_resources, resource_type,
                                      'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-communicationrequest',
                                      '2.0.1', true)
    end
  end
end
