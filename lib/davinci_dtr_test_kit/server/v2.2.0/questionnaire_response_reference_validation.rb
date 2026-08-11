# frozen_string_literal: true

require 'uri'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module QuestionnaireResponseReferenceValidation
      def questionnaire_responses_from_requests(requests)
        requests.filter_map do |request|
          resource = FHIR.from_contents(request.response_body)
          questionnaire_responses_from_resource(resource)
        rescue JSON::ParserError, FHIR::ClientException
          nil
        end.flatten
      end

      def questionnaire_responses_from_resource(resource)
        case resource&.resourceType
        when 'QuestionnaireResponse'
          [resource]
        when 'Bundle'
          resource.entry.filter_map do |entry|
            questionnaire_responses_from_resource(entry.resource)
          end.flatten
        when 'Parameters'
          resource.parameter.filter_map do |parameter|
            questionnaire_responses_from_resource(parameter.resource)
          end.flatten
        else
          []
        end
      end

      def invalid_questionnaire_response_references(questionnaire_response, client_fhir_endpoint)
        response_json = JSON.parse(questionnaire_response.to_json)
        contained_ids = response_json.fetch('contained', []).filter_map { |resource| resource['id'] }
        invalid_references = []

        questionnaire_response_references(response_json).each do |reference|
          reference_value = reference[:value]
          location = reference[:location]
          if reference_value.start_with?('#')
            invalid_references << "#{location} references `#{reference_value}`" \
              unless contained_ids.include?(reference_value.delete_prefix('#'))
          elsif invalid_absolute_reference?(reference_value, client_fhir_endpoint)
            invalid_references << "#{location} references `#{reference_value}`"
          end
        end

        invalid_references
      end

      def invalid_contained_reference_locations(questionnaire_response)
        response_json = JSON.parse(questionnaire_response.to_json)
        permitted_locations = answer_value_reference_locations(response_json.fetch('item', []))
        invalid_references = []

        questionnaire_response_references(response_json).each do |reference|
          reference_value = reference[:value]
          location = reference[:location]
          next unless reference_value.start_with?('#') && !permitted_locations.include?(location)

          invalid_references << "#{location} references `#{reference_value}`"
        end

        invalid_references
      end

      # Returns all populated FHIR Reference values below a JSON Hash or Array.
      #
      # Given:
      # { 'subject' => { 'reference' => 'Patient/123' },
      #   'item' => [{ 'answer' => [{ 'valueReference' => { 'reference' => '#observation' } }] }] }
      #
      # it returns:
      # [{ value: 'Patient/123', location: 'subject.reference' },
      #  { value: '#observation', location: 'item[0].answer[0].valueReference.reference' }]
      def questionnaire_response_references(value, location = nil)
        case value
        when Hash
          references_in_object(value, location)
        when Array
          references_in_array(value, location)
        else
          []
        end
      end

      def references_in_object(object, location)
        object.flat_map do |key, nested_value|
          nested_location = location.present? ? "#{location}.#{key}" : key
          references = questionnaire_response_references(nested_value, nested_location)
          next references unless key == 'reference' && nested_value.present?

          [{ value: nested_value, location: nested_location }] + references
        end
      end

      def references_in_array(array, location)
        array.flat_map.with_index do |nested_value, index|
          nested_location = location.present? ? "#{location}[#{index}]" : "[#{index}]"
          questionnaire_response_references(nested_value, nested_location)
        end
      end

      # Returns the locations of QuestionnaireResponse answer value references.
      #
      # Given items such as:
      # [{ 'answer' => [{ 'valueReference' => { 'reference' => '#observation' } }] }]
      #
      # it returns:
      # ['item[0].answer[0].valueReference.reference']
      def answer_value_reference_locations(items, item_location = 'item', locations = [])
        items.each_with_index do |item, item_index|
          location = "#{item_location}[#{item_index}]"
          answer_value_reference_locations(item.fetch('item', []), "#{location}.item", locations)

          item.fetch('answer', []).each_with_index do |answer, answer_index|
            answer_location = "#{location}.answer[#{answer_index}]"
            reference = answer.dig('valueReference', 'reference')
            locations << "#{answer_location}.valueReference.reference" if reference.present?
            answer_value_reference_locations(answer.fetch('item', []), "#{answer_location}.item", locations)
          end
        end

        locations
      end

      def absolute_reference?(reference)
        URI.parse(reference).absolute?
      rescue URI::InvalidURIError
        false
      end

      def questionnaire_response_has_absolute_reference?(questionnaire_response)
        response_json = JSON.parse(questionnaire_response.to_json)
        questionnaire_response_references(response_json).any? do |reference|
          absolute_reference?(reference[:value])
        end
      end

      def invalid_absolute_reference?(reference, client_fhir_endpoint)
        client_fhir_endpoint.present? && absolute_reference?(reference) &&
          !reference_on_client_endpoint?(reference, client_fhir_endpoint)
      end

      def reference_on_client_endpoint?(reference, client_fhir_endpoint)
        return false if client_fhir_endpoint.blank?

        normalized_endpoint = client_fhir_endpoint.delete_suffix('/')
        reference == normalized_endpoint || reference.start_with?("#{normalized_endpoint}/")
      end
    end
  end
end
