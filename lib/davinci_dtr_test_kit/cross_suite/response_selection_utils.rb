require_relative 'inferno_control_extensions'

module DaVinciDTRTestKit
  module ResponseSelectionUtils
    # ***********************************************************************
    # Selection of entries from the Template
    # ***********************************************************************

    def include_entity?(entity, parsed_request_body, operation)
      return false if entity_has_request_range_criteria?(entity) &&
                      !request_meets_request_range_criteria?(entity, operation)
      return false if entity_has_inclusion_criteria?(entity) &&
                      !request_meets_inclusion_criteria?(entity, parsed_request_body)

      true
    end

    def strip_inferno_extensions(entity)
      entity.extension.reject! { |ext| InfernoControlExtensions::ALL_URLS.include?(ext.url) }
      entity
    end

    # ***********************************************************************
    # FHIRPath-based selection criteria
    # ***********************************************************************

    def entity_has_inclusion_criteria?(entity)
      InfernoControlExtensions.find_extension(entity, InfernoControlExtensions::INCLUSION_CRITERIA_URL).present?
    end

    def request_meets_inclusion_criteria?(entity, parsed_request_body)
      criteria = InfernoControlExtensions.find_extension(entity, InfernoControlExtensions::INCLUSION_CRITERIA_URL)
        &.valueExpression&.expression
      return false unless criteria.present?

      fhirpath_result = execute_fhirpath(parsed_request_body, criteria)
      interpret_fhirpath_result_as_boolean(fhirpath_result)
    end

    # ***********************************************************************
    # request index-based selection criteria
    # ***********************************************************************

    def entity_has_request_range_criteria?(entity)
      InfernoControlExtensions.find_extension(entity, InfernoControlExtensions::REQUEST_RANGE_URL).present?
    end

    def request_meets_request_range_criteria?(entity, operation)
      criteria = InfernoControlExtensions.find_extension(entity, InfernoControlExtensions::REQUEST_RANGE_URL)
        &.valueString
      return false unless criteria.present?

      ranges_cover_value?(count_previous_successful_requests(operation) + 1, criteria)
    end

    def count_previous_successful_requests(operation)
      requests_repo = Inferno::Repositories::Requests.new
      previous_requests = requests_repo.requests_for_result(result.id)
      previous_requests.select { |req| req.url.include?(operation) && req.status == 200 }.count
    end

    def ranges_cover_value?(value, ranges_string)
      unless /\A(\d+(-\d+)?,)*\d+(-\d+)?\z/.match?(ranges_string)
        raise ArgumentError,
              "Invalid range string: #{ranges_string.inspect}"
      end

      ranges_string.split(',').any? do |part|
        if part.include?('-')
          a, b = part.split('-').map(&:to_i)
          raise ArgumentError, "Inverted range in: #{part.inspect}" if a > b

          (a..b).cover?(value)
        else
          part.to_i == value
        end
      end
    rescue ArgumentError => e
      raise Inferno::Exceptions::TestSuiteImplementationException.new('dtr response range criteria', e.message)
    end
  end
end
