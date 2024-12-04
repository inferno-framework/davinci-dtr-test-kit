module DaVinciDTRTestKit
  module UpdateTest
    def perform_update_test(update_resources, resource_type)
      skip_if(update_resources.blank?, 'No resources to update provided, skipping test.')
      assert_valid_json(update_resources)
      update_resources_list = JSON.parse(update_resources)
      skip_if(!update_resources_list.is_a?(Array), 'Resources to update not inputted in list format, skipping test.')

      valid_update_resources =
        update_resources_list
          .compact_blank
          .map { |resource| FHIR.from_contents(resource.to_json) }
          .select { |resource| resource.resourceType == resource_type }
          .select { |resource| resource_is_valid?(resource:) }

      skip_if(valid_update_resources.blank?,
              %(No valid #{resource_type} resources were provided to send in Update requests, skipping test.))

      valid_update_resources.each do |update_resource|
        fhir_update(update_resource, update_resource.id)
        assert_response_status([200, 201])
      end
    end
  end
end
