# frozen_string_literal: true

require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module QuestionnaireDesignSupport
      private

      def returned_questionnaires
        requests = load_tagged_requests(QUESTIONNAIRE_TAG) + load_tagged_requests(NEXT_TAG)
        questionnaires_from_requests(requests)
      end

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
    end
  end
end
