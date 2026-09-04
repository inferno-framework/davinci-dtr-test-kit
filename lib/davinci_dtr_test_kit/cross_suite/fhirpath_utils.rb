module DaVinciDTRTestKit
  module FhirpathUtils
    class FhirpathServiceError < StandardError; end

    def fhirpath_evaluator
      @fhirpath_evaluator ||= Inferno::DSL::FhirpathEvaluation::Evaluator.new
    end

    def execute_fhirpath(body, query)
      fhirpath_result = fhirpath_evaluator.call_fhirpath_service(body, query)
      return fhirpath_result if fhirpath_result.status.to_s.starts_with?('2')

      raise FhirpathServiceError,
            "FHIRPath service returned #{fhirpath_result.status} for query '#{query}' " \
            "on resource #{body}: #{fhirpath_result.body}"
    end

    def interpret_fhirpath_result_as_boolean(fhirpath_result)
      results = JSON.parse(fhirpath_result.body)
      if results.empty? || results.size > 1
        false
      elsif results.first['type'] == 'boolean'
        results.first['element']
      else
        true
      end
    rescue JSON::ParserError
      false
    end

    def replace_tokens_in_string(string, request)
      return string unless string.include?('{{')

      tokens_to_replace = string.scan(/\{\{([^}]+)\}\}/).flatten
      replacements = tokens_to_replace.each_with_object({}) do |expression, dictionary|
        next if dictionary.key?("{{#{expression}}}")

        dictionary["{{#{expression}}}"] = calculate_expression_string_value(request, expression)
      end

      string.gsub(/\{\{.*?\}\}/, replacements)
    end

    def calculate_expression_string_value(request, expression)
      JSON.parse(execute_fhirpath(request, expression).body)
        .map { |result| result['element'] }
        .map { |element| element.is_a?(Array) || element.is_a?(Hash) ? nil : element }
        .compact
        .join(',')
    end
  end
end
