module DaVinciDTRTestKit
  module ValidationTest

    def perform_request_validation_test(
      tag,
      resource_type,
      profile_url,
      resource_url)

      resources = load_tagged_requests(tag)
      omit_if resources.blank?,
              "No #{resource_type.to_s} resources provided so the #{profile_url} profile does not apply"
      resources.each do |resource|
        assert resource.url == resource_url,
          "Request made to wrong URL: #{resource.request[:url]}. Should instead be to #{resource_url}"
        assert_valid_json(resource.request[:body])
        params = FHIR.from_contents(resource.request[:body])
        assert params.present?, 'Request does not contain a recognized FHIR object'
        assert_resource_type(resource_type, resource: params)
        assert_valid_resource(resource: params,
                              profile_url: profile_url)
      end
    end
  end
end