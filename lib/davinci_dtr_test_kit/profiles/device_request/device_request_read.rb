require_relative '../../read_test'

module DaVinciDTRTestKit
  class DeviceRequestReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct DeviceRequest resource from DeviceRequest read interaction'
    description 'A server SHOULD support the DeviceRequest read interaction.'

    id :device_request_read
    optional
    input :device_request_ids,
          title: 'Device Request IDs',
          description: 'Comma separated list of DeviceRequest IDs',
          optional: true
    output :device_request_resources

    def resource_type
      'DeviceRequest'
    end

    def device_request_id_list
      return [nil] unless respond_to? :device_request_ids

      device_request_ids&.split(',')&.map(&:strip)
    end

    run do
      resources = perform_read_test(device_request_id_list, resource_type)

      output device_request_resources: resources.to_json
    end
  end
end
