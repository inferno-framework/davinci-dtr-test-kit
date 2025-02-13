module DaVinciDTRTestKit
  class ServiceRequestMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the ServiceRequest resources returned'
    description %(
      This test will look through the ServiceRequest resources
      found previously for the following must support elements:\n

      * ServiceRequest.authoredOn
      * ServiceRequest.basedOn
      * ServiceRequest.code
      * ServiceRequest.doNotPerform
      * ServiceRequest.extension:Coverage-Information
      * ServiceRequest.identifier
      * ServiceRequest.locationReference
      * ServiceRequest.occurrence[x]
      * ServiceRequest.performer
      * ServiceRequest.quantity[x]
      * ServiceRequest.reasonCode
      * ServiceRequest.reasonReference
      * ServiceRequest.requester
      * ServiceRequest.status
      * ServiceRequest.subject
    )
    id :service_request_must_support_test

    def resource_type
      'ServiceRequest'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:service_requests] ||= {}
    end

    run do
      skip_if(service_request_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
