require_relative '../../read_test'

module DaVinciDTRTestKit
  class DeviceRequestReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct DeviceRequest resource from DeviceRequest read interaction'
    description 'A server SHOULD support the DeviceRequest read interaction.'
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@272'

    id :device_request_read
    output :device_request_resources

    def resource_type
      'DeviceRequest'
    end

    def scratch_resources
      scratch[:device_requests] ||= {}
    end

    def device_request_id_list
      return [nil] unless respond_to? :device_request_ids

      device_request_ids&.split(',')&.map(&:strip)
    end

    run do
      perform_read_test(device_request_id_list, resource_type)
    end
  end
end
