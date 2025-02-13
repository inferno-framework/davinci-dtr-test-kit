module DaVinciDTRTestKit
  class TaskMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the Task resources returned'
    description %(
      This test will look through the Task resources
      found previously for the following must support elements:\n

      * Task.code
      * Task.for
      * Task.identifier
      * Task.input
      * Task.intent
      * Task.owner
      * Task.owner.identifier
      * Task.reasonCode.coding.code
      * Task.reasonReference
      * Task.requester
      * Task.requester.identifier
      * Task.restriction.period
      * Task.status
      * Task.statusReason
    )
    id :task_must_support_test

    def resource_type
      'Task'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:tasks] ||= {}
    end

    run do
      skip_if(task_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
