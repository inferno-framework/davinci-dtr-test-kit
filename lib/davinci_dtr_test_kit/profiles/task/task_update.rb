require_relative '../../update_test'

module DaVinciDTRTestKit
  class TaskUpdateTest < Inferno::Test
    include DaVinciDTRTestKit::UpdateTest

    title 'Server is capable of updating a Task resource from Task update interaction'
    description 'A server SHOULD support the Task update interaction'

    id :task_update
    optional
    input :update_task_resources,
          type: 'textarea',
          description:
          'Provide a list of Task resources to update. e.g., [json_resource_1, json_resource_2]',
          optional: true

    def resource_type
      'Task'
    end

    run do
      perform_update_test(update_task_resources, resource_type)
    end
  end
end
