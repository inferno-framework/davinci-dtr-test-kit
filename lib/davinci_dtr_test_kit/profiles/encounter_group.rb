require_relative 'encounter/encounter_read'
require_relative 'encounter/encounter_validation'

module DaVinciDTRTestKit
  class EncounterGroup < Inferno::TestGroup
    title 'CRD Encounter Tests'
    short_description 'Verify support for the server capabilities required by the CRD Encounter Profile'
    description %(
      # Background

    The CRD Encounter sequence verifies that the system under test is
    able to provide correct responses for Encounter queries. These queries
    must contain resources conforming to the CRD Encounter Profile as
    specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    This test sequence will first perform the required read associated
    with this resource. The server SHOULD be capable of returning a
    Encounter resource using the read interaction.

    ## Profile Validation
    Each resource returned from the first read is expected to conform to
    the [CRD Encounter Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-encounter).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :encounter_group
    run_as_group

    input :encounter_ids

    test from: :encounter_read
    test from: :encounter_validation
  end
end
