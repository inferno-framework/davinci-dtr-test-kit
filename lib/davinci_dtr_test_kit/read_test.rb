module DaVinciDTRTestKit
  module ReadTest
    def perform_read_test(resource_ids, resource_type)
      resources = []
      resource_ids.each do |id|
        fhir_read resource_type, id

        assert_response_status(200)
        assert_resource_type(resource_type)
        assert resource.id.present? && resource.id == id, bad_resource_id_message(id)

        resources.push(resource)
      end
      resources
    end

    def bad_resource_id_message(expected_id)
      "Expected resource to have id: `#{expected_id.inspect}`, but found `#{resource.id.inspect}`"
    end
  end
end
