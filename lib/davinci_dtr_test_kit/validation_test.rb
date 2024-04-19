module DaVinciDTRTestKit
  module ValidationTest

    def validate_resource(fhir_resource, resource_type, profile_url, index)
      assert fhir_resource.present?, 'Resource does not contain a recognized FHIR object'
      begin
        assert_resource_type(resource_type, resource: fhir_resource)
        assert_valid_resource(resource: fhir_resource,
                              profile_url: profile_url)
      rescue StandardError => e
        messages.each do |message|
          message[:message].prepend("[Resource #{index+1}] ")
        end
        raise e
      end
    end

    def perform_request_validation_test(
      resources,
      resource_type,
      profile_url,
      resource_url)
      omit_if resources.blank?,
            "No #{resource_type.to_s} resources provided so the #{profile_url} profile does not apply"
      resources.each_with_index do |resource, index|
        assert resource.url == resource_url,
          "Request made to wrong URL: #{resource.request[:url]}. Should instead be to #{resource_url}"
        assert_valid_json(resource.request[:body])
        fhir_resource = FHIR.from_contents(resource.request[:body])
        validate_resource(fhir_resource, resource_type, profile_url, index)
      end
    end

    def perform_response_validation_test(
      resources,
      resource_type,
      profile_url)
      # require 'debug/open_nonstop'
      # debugger
      omit_if resources.blank?,
          "No #{resource_type.to_s} resources provided so the #{profile_url} profile does not apply"
      resources.each_with_index do |resource, index|
        fhir_resource = FHIR.from_contents(resource.response[:body])
        assert_response_status(200, request: resource, response: resource.response)
        validate_resource(fhir_resource, resource_type, profile_url, index)
      end
    end
  end
end