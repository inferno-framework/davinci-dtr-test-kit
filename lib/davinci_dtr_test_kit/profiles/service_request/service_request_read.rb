require_relative '../../read_test'

module DaVinciDTRTestKit
  class ServiceRequestReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct ServiceRequest resource from ServiceRequest read interaction'
    description 'A server SHOULD support the ServiceRequest read interaction.'
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@276'

    id :service_request_read
    output :service_request_resources

    def resource_type
      'ServiceRequest'
    end

    def scratch_resources
      scratch[:service_requests] ||= {}
    end

    def service_request_id_list
      return [nil] unless respond_to? :service_request_ids

      service_request_ids&.split(',')&.map(&:strip)
    end

    run do
      perform_read_test(service_request_id_list, resource_type)
    end
  end
end
