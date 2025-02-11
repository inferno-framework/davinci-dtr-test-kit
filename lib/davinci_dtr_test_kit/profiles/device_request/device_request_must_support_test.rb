module DaVinciDTRTestKit
  class DeviceRequestMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the DeviceRequest resources returned'
    description %(
      This test will look through the DeviceRequest resources
      found previously for the following must support elements:\n

      * DeviceRequest.authoredOn
      * DeviceRequest.basedOn
      * DeviceRequest.code[x]
      * DeviceRequest.extension:Coverage-Information
      * DeviceRequest.identifier
      * DeviceRequest.occurrence[x]
      * DeviceRequest.parameter
      * DeviceRequest.performer
      * DeviceRequest.reasonCode
      * DeviceRequest.reasonReference
      * DeviceRequest.requester
      * DeviceRequest.status
      * DeviceRequest.subject
    )
    id :device_request_must_support_test

    def resource_type
      'DeviceRequest'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:device_request_resources] ||= {}
    end

    run do
      skip_if(device_request_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
