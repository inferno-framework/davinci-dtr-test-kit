require_relative 'communication_request/communication_request_read'
require_relative 'communication_request/communication_request_validation'
require_relative 'communication_request/communication_request_must_support_test'

module DaVinciDTRTestKit
  class CommunicationRequestGroup < Inferno::TestGroup
    title 'CRD CommunicationRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD CommunicationRequest Profile'
    description %(
      # Background

    The CRD CommunicationRequest sequence verifies that the system under test is
    able to provide correct responses for CommunicationRequest queries. These queries
    must return resources conforming to the [CRD CommunicationRequest Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-communicationrequest.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each CommunicationRequest resource id provided in
    the CommunicationRequest IDs input. The server SHOULD be capable of returning a
    CommunicationRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD CommunicationRequest Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-communicationrequest.html).
    Each element is checked against terminology binding and cardinality requirements.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the CommunicationRequest resources found in the first test for these
    elements.

    )
    id :communication_request_group
    optional
    run_as_group

    input :communication_request_ids,
          title: 'Communication Request IDs',
          description: 'Comma separated list of CommunicationRequest IDs',
          optional: true

    test from: :communication_request_read
    test from: :communication_request_validation
    test from: :communication_request_must_support_test
  end
end
