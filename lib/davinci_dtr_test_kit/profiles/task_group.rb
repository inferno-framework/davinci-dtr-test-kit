require_relative 'task/task_read'
require_relative 'task/task_validation'
require_relative 'task/task_create'
require_relative 'task/task_update'

module DaVinciDTRTestKit
  class TaskGroup < Inferno::TestGroup
    title 'PAS Task Tests'
    short_description 'Verify support for the server capabilities required by the PAS Task Profile'
    description %(
      # Background

    The PAS Task sequence verifies that the system under test is
    able to provide correct responses for Task queries. These queries
    must contain resources conforming to the PAS Task Profile as
    specified in the DaVinci Prior Authorization Support (PAS) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each Task resource id provided in
    the Task ids input. The server SHOULD be capable of returning a
    Task resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [PAS Task Profile](http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-task). Each
    element is checked against terminology binding and cardinality requirements.

    ## Create
    This test sequence will perform create interactions with the provided json
    Task resources. The server SHOULD be capable of creating a Task resource
    using the create interaction.

    ## Update
    This test sequence will perform update interactions with the provided json
    Task resources. The server SHOULD be capable of creating a Task resource
    using the update interaction.
          )
    id :task_group
    run_as_group

    input :task_ids,
          title: 'Task IDs',
          description: 'Comma separated list of Task IDs'

    test from: :task_read
    test from: :task_validation
    test from: :task_create
    test from: :task_update
  end
end
