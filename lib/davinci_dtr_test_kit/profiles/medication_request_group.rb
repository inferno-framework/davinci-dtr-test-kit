require_relative 'medication_request/medication_request_read'
require_relative 'medication_request/medication_request_validation'

module DaVinciDTRTestKit
  class MedicationRequestGroup < Inferno::TestGroup
    title 'CRD MedicationRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD MedicationRequest Profile'
    description %(
      # Background

    The CRD MedicationRequest sequence verifies that the system under test is
    able to provide correct responses for MedicationRequest queries. These queries
    must return resources conforming to the [CRD MedicationRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-medicationrequest)
    as specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each MedicationRequest resource id provided in
    the MedicationRequest ids input. The server SHOULD be capable of returning a
    MedicationRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD MedicationRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-medicationrequest).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :medication_request_group
    run_as_group

    input :medication_request_ids

    test from: :medication_request_read
    test from: :medication_request_validation
  end
end
