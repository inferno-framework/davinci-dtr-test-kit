require_relative 'communication_request/communication_request_read'
require_relative 'communication_request/communication_request_validation'

module DaVinciDTRTestKit
  class CommunicationRequestGroup < Inferno::TestGroup
    title 'CRD CommunicationRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD CommunicationRequest Profile'
    description %(
      # Background

    The CRD CommunicationRequest sequence verifies that the system under test is
    able to provide correct responses for CommunicationRequest queries. These queries
    must return resources conforming to the [CRD CommunicationRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-communicationrequest).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each CommunicationRequest resource id provided in
    the CommunicationRequest ids input. The server SHOULD be capable of returning a
    CommunicationRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD CommunicationRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-communicationrequest).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :communication_request_group
    run_as_group

    input :communication_request_ids,
          title: 'Communication Request IDs',
          description: 'Comma separated list of CommunicationRequest IDs',
          optional: true

    test from: :communication_request_read
    test from: :communication_request_validation
  end
end
