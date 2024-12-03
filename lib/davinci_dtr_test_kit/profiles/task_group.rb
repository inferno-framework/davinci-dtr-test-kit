require_relative 'task/task_read'
require_relative 'task/task_validation'
require_relative 'task/task_create'
require_relative 'task/task_update'

module DaVinciDTRTestKit
  class TaskGroup < Inferno::TestGroup
    title 'CDex Task Tests'
    short_description 'Verify support for the server capabilities required by the CDex Task Profile'
    description %(
      # Background

    The CDex Task sequence verifies that the system under test is
    able to provide correct responses for Task queries. These queries
    must contain resources conforming to the CDex Task Profile as
    specified in the DaVinci Clinical Data Exchange (CDex) v2.0.0
    Implementation Guide.

    # Testing Methodology
    ## Read
    This test sequence will first perform the required read associated
    with this resource. The server SHOULD be capable of returning a
    Task resource using the read interaction.

    ## Profile Validation
    Each resource returned from the first read is expected to conform to
    the [CDex Task Profile](http://hl7.org/fhir/us/davinci-cdex/StructureDefinition/cdex-task-attachment-request). Each
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

    input :task_ids

    test from: :task_read
    test from: :task_validation
    test from: :task_create
    test from: :task_update
  end
end
