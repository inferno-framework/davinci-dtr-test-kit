# frozen_string_literal: true

require_relative 'questionnaire_design_support'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireExpressionLanguageTest < Inferno::Test
      include QuestionnaireDesignSupport

      id :dtr_v220_payer_questionnaire_expression_language
      title 'Questionnaire flow and rendering expressions use CQL'
      description %(
        Inferno verifies that Expression-valued Questionnaire item extensions are
        written in CQL. This requirement is conditional and is omitted when no
        such expressions are present.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-18'

      run do
        questionnaire_details = returned_questionnaires
        skip_if questionnaire_details.blank?, 'No Questionnaire resources were returned'

        expressions = questionnaire_details.flat_map { |details| questionnaire_item_expressions(details) }
        omit_if expressions.blank?, 'No flow or rendering expressions were found'

        non_cql_expressions = expressions.reject do |details|
          cql_expression?(details[:expression])
        end
        non_cql_details = non_cql_expressions.map do |details|
          language = details[:expression].language.presence || 'missing'
          "#{request_location(details[:request_details])} linkId `#{details[:link_id]}` (language `#{language}`)"
        end

        assert non_cql_expressions.blank?,
               "The following flow or rendering expressions were not written in CQL: #{non_cql_details.join(', ')}"
      end

      private

      def questionnaire_item_expressions(details)
        questionnaire = details[:questionnaire]
        questionnaire_items(questionnaire).flat_map do |item|
          item.extension.flat_map do |extension|
            expressions_from_extension(extension).map do |expression|
              { expression:, link_id: item.linkId, request_details: details }
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

      def request_location(details)
        "#{details[:operation]} request #{details[:request_index] + 1}"
      end
    end
  end
end
