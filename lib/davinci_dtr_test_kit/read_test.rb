module DaVinciDTRTestKit
  module ReadTest
    def perform_read_test(resource_ids, resource_type)
      resources = []
      resource_ids.each do |id|
        fhir_read resource_type, id

        assert_response_status(200)

        resources.push(resource)
      end
      resources
    end
  end
end
