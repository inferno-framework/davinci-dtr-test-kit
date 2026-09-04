# frozen_string_literal: true

require 'uri'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module QuestionnaireResponseReferenceValidation
      def questionnaire_responses_from_request(request)
        resource = FHIR.from_contents(request.response_body)
        questionnaire_responses_from_resource(resource)
      rescue JSON::ParserError, FHIR::ClientException
        []
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
        contained_ids = questionnaire_response.contained.filter_map(&:id)
        invalid_references = []

        questionnaire_response_references(questionnaire_response).each do |reference|
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
        permitted_locations = answer_value_reference_locations(questionnaire_response.item)
        invalid_references = []

        questionnaire_response_references(questionnaire_response).each do |reference|
          reference_value = reference[:value]
          location = reference[:location]
          next unless reference_value.start_with?('#') && !permitted_locations.include?(location)

          invalid_references << "#{location} references `#{reference_value}`"
        end

        invalid_references
      end

      # Returns all populated FHIR Reference values below a FHIR resource.
      #
      # Given a QuestionnaireResponse with the following JSON representation:
      # { "subject": { "reference": "Patient/123" },
      #   "item": [{ "answer": [{ "valueReference": { "reference": "#observation" } }] }] }
      #
      # it returns:
      # [{ value: 'Patient/123', location: 'subject.reference' },
      #  { value: '#observation', location: 'item[0].answer[0].valueReference.reference' }]
      def questionnaire_response_references(questionnaire_response)
        references = []

        questionnaire_response.each_element do |element, _metadata, path|
          next unless element.is_a?(FHIR::Reference) && element.reference.present?

          references << { value: element.reference, location: "#{path}.reference" }
        end

        references
      end

      # Returns the locations of QuestionnaireResponse answer value references.
      #
      # Given QuestionnaireResponse items with the following JSON representation:
      # [{ "answer": [{ "valueReference": { "reference": "#observation" } }] }]
      #
      # it returns:
      # ['item[0].answer[0].valueReference.reference']
      def answer_value_reference_locations(items, item_location = 'item', locations = [])
        items.each_with_index do |item, item_index|
          location = "#{item_location}[#{item_index}]"
          answer_value_reference_locations(item.item, "#{location}.item", locations)

          item.answer.each_with_index do |answer, answer_index|
            answer_location = "#{location}.answer[#{answer_index}]"
            locations << "#{answer_location}.valueReference.reference" if answer.valueReference&.reference.present?
            answer_value_reference_locations(answer.item, "#{answer_location}.item", locations)
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
        questionnaire_response_references(questionnaire_response).any? do |reference|
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
