require_relative 'vision_prescription/vision_prescription_read'
require_relative 'vision_prescription/vision_prescription_validation'

module DaVinciDTRTestKit
  class VisionPrescriptionGroup < Inferno::TestGroup
    title 'CRD VisionPrescription Tests'
    short_description 'Verify support for the server capabilities required by the CRD VisionPrescription Profile'
    description %(
      # Background

    The CRD VisionPrescription sequence verifies that the system under test is
    able to provide correct responses for VisionPrescription queries. These queries
    must return resources conforming to the [CRD VisionPrescription Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-visionprescription)
    as specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each VisionPrescription resource id provided in
    the VisionPrescription ids input. The server SHOULD be capable of returning a
    VisionPrescription resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD VisionPrescription Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-visionprescription).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :vision_prescription_group
    run_as_group

    input :vision_prescription_ids,
          title: 'Vision Prescription IDs',
          description: 'Comma separated list of VisionPrescription IDs',
          optional: true

    test from: :vision_prescription_read
    test from: :vision_prescription_validation
  end
end
