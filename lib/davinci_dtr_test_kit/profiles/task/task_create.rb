require_relative '../../create_test'

module DaVinciDTRTestKit
  class TaskCreateTest < Inferno::Test
    include DaVinciDTRTestKit::CreateTest

    title 'Server is capable of creating a Task resource from Task create interaction'
    description 'A server SHOULD support the Task create interaction'

    id :task_create
    input :create_task_resources

    def resource_type
      'Task'
    end

    run do
      perform_create_test(create_task_resources, resource_type)
    end
  end
end
