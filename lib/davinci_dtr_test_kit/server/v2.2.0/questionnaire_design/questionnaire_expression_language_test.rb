# frozen_string_literal: true

require_relative 'questionnaire_design_support'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireExpressionLanguageTest < Inferno::Test
      include QuestionnaireDesignSupport

      CQL_MEDIA_TYPES = [
        'text/cql',
        'text/cql-expression',
        'text/cql-identifier'
      ].freeze

      id :dtr_v220_payer_questionnaire_expression_language
      title 'Questionnaire flow and rendering expressions use CQL'
      description %(
        Inferno verifies that Expression-valued Questionnaire item extensions are
        written in CQL. This requirement is conditional and is omitted when no
        such expressions are present.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-18'

      run do
        questionnaires = returned_questionnaires
        skip_if questionnaires.blank?, 'No Questionnaire resources were returned'

        expressions = questionnaires.flat_map { |questionnaire| questionnaire_item_expressions(questionnaire) }
        omit_if expressions.blank?, 'No flow or rendering expressions were found'

        non_cql_expressions = expressions.reject do |details|
          expression_uses_cql?(details[:expression])
        end
        non_cql_details = non_cql_expressions.map do |details|
          language = details[:expression].language.presence || 'missing'
          "linkId `#{details[:link_id]}` (language `#{language}`)"
        end

        assert non_cql_expressions.blank?,
               "The following flow or rendering expressions were not written in CQL: #{non_cql_details.join(', ')}"
      end

      private

      def questionnaire_item_expressions(questionnaire)
        questionnaire_items(questionnaire).flat_map do |item|
          item.extension.flat_map do |extension|
            expressions_from_extension(extension).map do |expression|
              { expression:, link_id: item.linkId }
            end
          end
        end
      end

      def expressions_from_extension(extension)
        [
          extension.valueExpression,
          *extension.extension.flat_map { |nested_extension| expressions_from_extension(nested_extension) }
        ].compact
      end

      def expression_uses_cql?(expression)
        CQL_MEDIA_TYPES.include?(expression.language.to_s.split(';').first.strip)
      end
    end
  end
end
