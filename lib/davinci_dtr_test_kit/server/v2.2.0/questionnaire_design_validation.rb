# frozen_string_literal: true

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module QuestionnaireDesignValidation
      ENABLE_WHEN_EXPRESSION_URL =
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression'

      PREPOPULATION_EXTENSION_URLS = [
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext',
        'http://hl7.org/fhir/StructureDefinition/variable',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext',
        'http://hl7.org/fhir/StructureDefinition/cqf-library'
      ].freeze

      def questionnaires_from_requests(requests)
        requests.filter_map do |request|
          next if request.response_body.blank?

          resource = FHIR.from_contents(request.response_body)
          questionnaires_from_resource(resource)
        rescue JSON::ParserError, FHIR::ClientException
          nil
        end.flatten
      end

      def questionnaires_from_resource(resource)
        case resource.resourceType
        when 'Questionnaire'
          [resource]
        when 'QuestionnaireResponse'
          resource.contained.grep(FHIR::Questionnaire)
        when 'Bundle'
          questionnaires_from_resources(resource.entry.map(&:resource))
        when 'Parameters'
          questionnaires_from_resources(resource.parameter.map(&:resource))
        else
          []
        end
      end

      def questionnaires_from_resources(resources)
        resources.compact.flat_map { |resource| questionnaires_from_resource(resource) }
      end

      def questionnaire_items(questionnaire)
        questionnaire.item.flat_map { |item| [item] + questionnaire_items(item) }
      end

      def questionnaire_has_relevance_logic?(questionnaire)
        questionnaire_items(questionnaire).any? do |item|
          item.enableWhen.present? || item.extension.any? { |extension| extension.url == ENABLE_WHEN_EXPRESSION_URL }
        end
      end

      def questionnaire_has_prepopulation_logic?(questionnaire)
        questionnaire.extension.any? { |extension| PREPOPULATION_EXTENSION_URLS.include?(extension.url) }
      end

      def questionnaire_item_expressions(questionnaire)
        questionnaire_items(questionnaire).flat_map do |item|
          item.extension.filter_map do |extension|
            next unless extension.valueExpression

            { expression: extension.valueExpression, link_id: item.linkId }
          end
        end
      end
    end
  end
end