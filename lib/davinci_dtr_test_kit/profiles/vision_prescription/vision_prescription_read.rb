require_relative '../../read_test'

module DaVinciDTRTestKit
  class VisionPrescriptionReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct VisionPrescription resource from VisionPrescription read interaction'
    description 'A server SHALL support the VisionPrescription read interaction.'

    id :vision_prescription_read
    output :vision_prescription_resources

    def resource_type
      'VisionPrescription'
    end

    def vision_prescription_id_list
      return [nil] unless respond_to? :vision_prescription_ids

      vision_prescription_ids.split(',').map(&:strip)
    end

    run do
      resources = perform_read_test(vision_prescription_id_list, resource_type)

      output vision_prescription_resources: resources.to_json
    end
  end
end
