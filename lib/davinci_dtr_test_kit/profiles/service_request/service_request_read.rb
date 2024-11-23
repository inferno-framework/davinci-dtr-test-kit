require_relative '../../read_test'

module DaVinciDTRTestKit
  class ServiceRequestReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct ServiceRequest resource from ServiceRequest read interaction'
    description 'A server SHOULD support the ServiceRequest read interaction.'

    id :service_request_read
    output :service_request_resources

    def resource_type
      'ServiceRequest'
    end

    def service_request_id_list
      return [nil] unless respond_to? :service_request_ids

      service_request_ids.split(',').map(&:strip)
    end

    run do
      resources = perform_read_test(service_request_id_list, resource_type)

      output service_request_resources: resources.to_json
    end
  end
end
