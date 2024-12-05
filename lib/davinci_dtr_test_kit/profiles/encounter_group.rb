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
    must return resources conforming to the [CRD Encounter Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-encounter.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each Encounter resource id provided in
    the Encounter IDs input. The server SHOULD be capable of returning a
    Encounter resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD Encounter Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-encounter.html).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :encounter_group
    run_as_group

    input :encounter_ids,
          title: 'Encounter IDs',
          description: 'Comma separated list of Encounter IDs',
          optional: true

    test from: :encounter_read
    test from: :encounter_validation
  end
end
