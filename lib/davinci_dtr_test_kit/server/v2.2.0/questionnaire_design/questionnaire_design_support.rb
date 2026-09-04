# frozen_string_literal: true

require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module QuestionnaireDesignSupport
      CQL_MEDIA_TYPES = [
        'text/cql',
        'text/cql-expression',
        'text/cql-identifier'
      ].freeze

      private

      # Returns a Hash for each Questionnaire returned in a tagged response:
      # { questionnaire:, operation:, request_index: }
      # request_index is scoped independently to each operation.
      def returned_questionnaires
        questionnaires_from_requests(load_tagged_requests(QUESTIONNAIRE_TAG), '$questionnaire-package') +
          questionnaires_from_requests(load_tagged_requests(NEXT_TAG), '$next-question')
      end

      def questionnaires_from_requests(requests, operation)
        requests.each_with_index.flat_map do |request, request_index|
          next [] if request.response_body.blank?

          resource = FHIR.from_contents(request.response_body)
          questionnaires_from_resource(resource).map do |questionnaire|
            { questionnaire:, operation:, request_index: }
          end
        rescue JSON::ParserError, FHIR::ClientException
          []
        end
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

      def cql_expression?(expression)
        CQL_MEDIA_TYPES.include?(expression.language.to_s.split(';').first.strip)
      end
    end
  end
end
