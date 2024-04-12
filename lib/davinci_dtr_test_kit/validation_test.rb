module DaVinciDTRTestKit
  module ValidationTest

    def validate_resource(fhir_resource, resource_type, profile_url)
      assert fhir_resource.present?, 'Resource does not contain a recognized FHIR object'
      assert_resource_type(resource_type, resource: fhir_resource)
      assert_valid_resource(resource: fhir_resource,
                            profile_url: profile_url)
    end

    def perform_request_validation_test(
      resources,
      resource_type,
      profile_url,
      resource_url)
      omit_if resources.blank?,
            "No #{resource_type.to_s} resources provided so the #{profile_url} profile does not apply"
      resources.each do |resource|
        assert resource.url == resource_url,
          "Request made to wrong URL: #{resource.request[:url]}. Should instead be to #{resource_url}"
        assert_valid_json(resource.request[:body])
        fhir_resource = FHIR.from_contents(resource.request[:body])
        validate_resource(fhir_resource, resource_type, profile_url)
      end
    end

    def perform_response_validation_test(
      resources,
      resource_type,
      profile_url)
      omit_if resources.blank?,
          "No #{resource_type.to_s} resources provided so the #{profile_url} profile does not apply"
      resources.each do |resource|
        fhir_resource = FHIR.from_contents(resource.response[:body])
        assert_response_status(200, request: resource, response: resource.response)
        validate_resource(fhir_resource, resource_type, profile_url)
      end
    end
  end
end