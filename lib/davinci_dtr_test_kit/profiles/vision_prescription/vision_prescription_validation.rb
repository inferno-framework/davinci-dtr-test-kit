require_relative '../../validation_test'

module DaVinciDTRTestKit
  class VisionPrescriptionValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest

    title 'VisionPrescription resources returned during previous tests conform to the CRD VisionPrescription'
    description %(
This test verifies resources returned from the read step conform to
the [CRD VisionPrescription](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-visionprescription).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :vision_prescription_validation
    input :vision_prescription_resources,
          optional: true

    def resource_type
      'VisionPrescription'
    end

    run do
      skip_if(vision_prescription_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_profile_validation_test(vision_prescription_resources, resource_type,
                                      'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-visionprescription|2.0.1')
    end
  end
end
