require_relative 'task/task_read'
require_relative 'task/task_validation'
require_relative 'task/task_create'
require_relative 'task/task_update'
require_relative 'task/task_must_support_test'

module DaVinciDTRTestKit
  class TaskGroup < Inferno::TestGroup
    title 'PAS Task Tests'
    short_description 'Verify support for the server capabilities required by the PAS Task Profile'
    description %(
      # Background

    The PAS Task sequence verifies that the system under test is
    able to provide correct responses for Task queries. These queries
    must contain resources conforming to the [PAS Task Profile](http://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each Task resource id provided in
    the Task IDs input. The server SHOULD be capable of returning a
    Task resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [PAS Task Profile](http://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-profile-task.html). Each
    element is checked against terminology binding and cardinality requirements.

    ## Create
    This test sequence will perform create interactions with the provided json
    Task resources. The server SHOULD be capable of creating a Task resource
    using the create interaction.

    ## Update
    This test sequence will perform update interactions with the provided json
    Task resources. The server SHOULD be capable of creating a Task resource
    using the update interaction.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the Task resources found in the first test for these
    elements.

    )
    id :task_group
    optional
    run_as_group

    input :task_ids,
          title: 'Task IDs',
          description: 'Comma separated list of Task IDs',
          optional: true

    test from: :task_read
    test from: :task_validation
    test from: :task_create
    test from: :task_update
    test from: :task_must_support_test
  end
end
