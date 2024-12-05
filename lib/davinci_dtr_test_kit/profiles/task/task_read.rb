require_relative '../../read_test'

module DaVinciDTRTestKit
  class TaskReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct Task resource from Task read interaction'
    description 'A server SHOULD support the Task read interaction.'

    id :task_read
    optional
    output :task_resources

    def resource_type
      'Task'
    end

    def task_id_list
      return [nil] unless respond_to? :task_ids

      task_ids&.split(',')&.map(&:strip)
    end

    run do
      resources = perform_read_test(task_id_list, resource_type)

      output task_resources: resources.to_json
    end
  end
end
