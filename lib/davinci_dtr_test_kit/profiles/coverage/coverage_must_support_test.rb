module DaVinciDTRTestKit
  class CoverageMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the Coverage resources returned'
    description %(
      This test will look through the Coverage resources
      found previously for the following must support elements:\n

      * Coverage.beneficiary
      * Coverage.class
      * Coverage.class:group
      * Coverage.class:group.name
      * Coverage.class:group.value
      * Coverage.class:plan
      * Coverage.class:plan.name
      * Coverage.class:plan.value
      * Coverage.dependent
      * Coverage.identifier
      * Coverage.identifier:MBIdentifier
      * Coverage.identifier:MBIdentifier.type
      * Coverage.network
      * Coverage.order
      * Coverage.payor
      * Coverage.period
      * Coverage.policyHolder
      * Coverage.relationship
      * Coverage.status
      * Coverage.subscriber
      * Coverage.subscriberId
      * Coverage.type
    )
    id :coverage_must_support_test

    def resource_type
      'Coverage'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:coverage_resources] ||= {}
    end

    run do
      skip_if(coverage_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
