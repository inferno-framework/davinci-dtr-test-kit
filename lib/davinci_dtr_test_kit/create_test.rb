module DaVinciDTRTestKit
  module CreateTest
    def perform_create_test(create_resources, resource_type)
      assert_valid_json(create_resources)
      create_resources_list = JSON.parse(create_resources)
      skip_if(!create_resources_list.is_a?(Array), 'Resources to create not inputted in list format, skipping test.')

      valid_create_resources =
        create_resources_list
          .compact_blank
          .map { |resource| FHIR.from_contents(resource.to_json) }
          .select { |resource| resource.resourceType == resource_type }
          .select { |resource| resource_is_valid?(resource:) }

      skip_if(valid_create_resources.blank?,
              %(No valid #{resource_type} resources were provided to send in Create requests, skipping test.))

      valid_create_resources.each do |create_resource|
        fhir_create(create_resource)
        assert_response_status(201)
      end
    end
  end
end
