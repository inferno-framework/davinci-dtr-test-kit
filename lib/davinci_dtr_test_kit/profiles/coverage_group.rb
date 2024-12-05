require_relative 'coverage/coverage_read'
require_relative 'coverage/coverage_validation'

module DaVinciDTRTestKit
  class CoverageGroup < Inferno::TestGroup
    title 'CRD Coverage Tests'
    short_description 'Verify support for the server capabilities required by the CRD Coverage Profile'
    description %(
      # Background

    The CRD Coverage sequence verifies that the system under test is
    able to provide correct responses for Coverage queries. These queries
    must return resources conforming to the [CRD Coverage Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage)
    as specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each Coverage resource id provided in
    the Coverage ids input. The server SHALL be capable of returning a
    Coverage resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD Coverage Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :coverage_group
    run_as_group

    input :coverage_ids,
          title: 'Coverage IDs',
          description: 'Comma separated list of Coverage IDs',
          optional: true

    test from: :coverage_read
    test from: :coverage_validation
  end
end
