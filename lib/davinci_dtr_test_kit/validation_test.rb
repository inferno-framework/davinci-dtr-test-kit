module DaVinciDTRTestKit
  module ValidationTest
    def tests_failed
      @tests_failed ||= {}
    end

    def using_manual_tests(resource_url)
      return !next_question_requests.nil? if resource_url == next_url
      return !initial_questionnaire_request.nil? if resource_url == questionnaire_package_url

      !(initial_questionnaire_request.nil? || next_question_requests.nil?)
    end

    def validate_resource(fhir_resource, resource_type, profile_url, index)
      assert fhir_resource.present?, 'Resource does not contain a recognized FHIR object'
      begin
        assert_resource_type(resource_type, resource: fhir_resource)
        assert_valid_resource(resource: fhir_resource,
                              profile_url:)
      rescue StandardError => e
        messages.each do |message|
          message[:message].prepend("[Resource #{index + 1}] ")
        end
        if tests_failed[profile_url].blank?
          tests_failed[profile_url] = [e]
        else
          tests_failed[profile_url] << e
        end
      end
    end

    def perform_request_validation_test(
      resources,
      resource_type,
      profile_url,
      resource_url
    )
      omit_if resources.blank?,
              "No #{resource_type} resources provided so the #{profile_url} profile does not apply"
      resources = JSON.parse(resources) if using_manual_tests(resource_url)
      resources = [resources] unless resources.is_a?(Array)
      resources.each_with_index do |resource, index|
        if using_manual_tests(resource_url)
          assert_valid_json(resource.to_json)
          fhir_resource = FHIR.from_contents(resource.to_json)
        else
          assert resource.url == resource_url,
                 "Request made to wrong URL: #{resource.request[:url]}. Should instead be to #{resource_url}"
          assert_valid_json(resource.request[:body])
          fhir_resource = FHIR.from_contents(resource.request[:body])
        end
        validate_resource(fhir_resource, resource_type, profile_url, index)
      end
      return if tests_failed[profile_url].blank?

      raise tests_failed[profile_url][0]
    end

    def perform_response_validation_test(
      resources,
      resource_type,
      profile_url
    )
      omit_if resources.blank?,
              "No #{resource_type} resources provided so the #{profile_url} profile does not apply"
      resources.each_with_index do |resource, index|
        fhir_resource = FHIR.from_contents(resource.response[:body])
        assert_response_status([200, 202], request: resource, response: resource.response)
        validate_resource(fhir_resource, resource_type, profile_url, index)
      end
      return if tests_failed[profile_url].blank?

      raise tests_failed[profile_url][0]
    end
  end
end
