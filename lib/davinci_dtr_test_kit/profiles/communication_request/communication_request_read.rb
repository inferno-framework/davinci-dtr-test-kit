require_relative '../../read_test'

module DaVinciDTRTestKit
  class CommunicationRequestReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct CommunicationRequest resource from CommunicationRequest read interaction'
    description 'A server SHALL support the CommunicationRequest read interaction.'

    id :communication_request_read
    output :communication_request_resources

    def resource_type
      'CommunicationRequest'
    end

    def communication_request_id_list
      return [nil] unless respond_to? :communication_request_ids

      communication_request_ids.split(',').map(&:strip)
    end

    run do
      resources = perform_read_test(communication_request_id_list, resource_type)

      output communication_request_resources: resources.to_json
    end
  end
end
