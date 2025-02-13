require_relative 'coverage/coverage_read'
require_relative 'coverage/coverage_validation'
require_relative 'coverage/coverage_must_support_test'

module DaVinciDTRTestKit
  class CoverageGroup < Inferno::TestGroup
    title 'CRD Coverage Tests'
    short_description 'Verify support for the server capabilities required by the CRD Coverage Profile'
    description %(
      # Background

    The CRD Coverage sequence verifies that the system under test is
    able to provide correct responses for Coverage queries. These queries
    must return resources conforming to the [CRD Coverage Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-coverage.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each Coverage resource id provided in
    the Coverage IDs input. The server SHALL be capable of returning a
    Coverage resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD Coverage Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-coverage.html).
    Each element is checked against terminology binding and cardinality requirements.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the Coverage resources found in the first test for these
    elements.
    )
    id :coverage_group
    run_as_group

    input :coverage_ids,
          title: 'Coverage IDs',
          description: 'Comma separated list of Coverage IDs',
          optional: true

    test from: :coverage_read
    test from: :coverage_validation
    test from: :coverage_must_support_test
  end
end
