module DaVinciDTRTestKit
  module ValidationTest
    def tests_failed
      @tests_failed ||= {}
    end

    def validate_resource(fhir_resource, resource_type, profile_url, index) # rubocop:disable Naming/PredicateMethod
      begin
        assert fhir_resource.present?, 'Resource does not contain a recognized FHIR object'
        assert_resource_type(resource_type, resource: fhir_resource)
        assert_valid_resource(resource: fhir_resource,
                              profile_url:)
      rescue StandardError => e
        add_message('error', e.message)
        messages.each do |message|
          message[:message].prepend("[Resource #{index + 1}] ") unless message[:message].start_with? '[Resource'
        end
        if tests_failed[profile_url].blank?
          tests_failed[profile_url] = [e]
        else
          tests_failed[profile_url] << e
        end
        return false
      end
      true
    end

    def perform_profile_validation_test(
      resources,
      resource_type,
      profile_url
    )
      skip_if(resources.nil?, "No `#{resource_type}` resources to validate, skipping test.")
      resources = JSON.parse(resources)
      resources = [resources] unless resources.is_a?(Array)
      resources.each do |resource|
        fhir_resource = FHIR.from_contents(resource.to_json)

        assert fhir_resource.present?, 'Resource does not contain a recognized FHIR object'
        assert_resource_type(resource_type, resource: fhir_resource)
        assert_valid_resource(resource: fhir_resource,
                              profile_url:)
      end
    end

    def perform_request_validation_test(
      resources,
      resource_type,
      profile_url,
      resource_url,
      using_manual_entry
    )
      omit_if resources.blank?,
              "No #{resource_type} resources provided so the #{profile_url} profile does not apply"
      resources = JSON.parse(resources) if using_manual_entry
      resources = [resources] unless resources.is_a?(Array)
      resources.each_with_index do |resource, index|
        if using_manual_entry
          fhir_resource = FHIR.from_contents(resource.to_json)
        else
          if resource.url != resource_url
            messages << { type: 'warning',
                          message: format_markdown(%(Request made to wrong URL: #{resource.request[:url]}.
                                                     Should instead be to #{resource_url})) }
          end
          fhir_resource = FHIR.from_contents(resource.request[:body])
        end
        validate_resource(fhir_resource, resource_type, profile_url, index)
      end
    end

    def perform_response_validation_test(
      resources,
      resource_type,
      profile_url
    )
      omit_if resources.blank?,
              "No #{resource_type} resources provided so the #{profile_url} profile does not apply"
      resources.each_with_index do |resource, index|
        validate_resource(resource, resource_type, profile_url, index)
      end
      return if tests_failed[profile_url].blank?

      raise tests_failed[profile_url][0]
    end
  end
end
