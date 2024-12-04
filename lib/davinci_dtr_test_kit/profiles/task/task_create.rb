require_relative '../../create_test'

module DaVinciDTRTestKit
  class TaskCreateTest < Inferno::Test
    include DaVinciDTRTestKit::CreateTest

    title 'Server is capable of creating a Task resource from Task create interaction'
    description 'A server SHOULD support the Task create interaction'

    id :task_create
    optional
    input :create_task_resources,
          type: 'textarea',
          description:
          'Provide a list of Task resources to create. e.g., [json_resource_1, json_resource_2]',
          optional: true

    def resource_type
      'Task'
    end

    run do
      perform_create_test(create_task_resources, resource_type)
    end
  end
end
