require_relative '../../read_test'

module DaVinciDTRTestKit
  class MedicationRequestReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct MedicationRequest resource from MedicationRequest read interaction'
    description 'A server SHOULD support the MedicationRequest read interaction.'

    id :medication_request_read
    output :medication_request_resources

    def resource_type
      'MedicationRequest'
    end

    def scratch_resources
      scratch[:medication_requests] ||= {}
    end

    def medication_request_id_list
      return [nil] unless respond_to? :medication_request_ids

      medication_request_ids&.split(',')&.map(&:strip)
    end

    run do
      perform_read_test(medication_request_id_list, resource_type)
    end
  end
end
