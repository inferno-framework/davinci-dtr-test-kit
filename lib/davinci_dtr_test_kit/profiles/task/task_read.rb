require_relative '../../read_test'

module DaVinciDTRTestKit
  class TaskReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct Task resource from Task read interaction'
    description 'A server SHOULD support the Task read interaction.'

    id :task_read
    output :task_resources

    def resource_type
      'Task'
    end

    def scratch_resources
      scratch[:tasks] ||= {}
    end

    def task_id_list
      return [nil] unless respond_to? :task_ids

      task_ids&.split(',')&.map(&:strip)
    end

    run do
      perform_read_test(task_id_list, resource_type)
    end
  end
end
