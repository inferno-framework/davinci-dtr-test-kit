# frozen_string_literal: true

require_relative 'questionnaire_design_support'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireExpressionElmTest < Inferno::Test
      include QuestionnaireDesignSupport

      ALTERNATIVE_EXPRESSION_URL =
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression'

      id :dtr_v220_payer_questionnaire_expression_elm
      title 'Questionnaire expressions include compiled JSON ELM'
      description %(
        Inferno verifies that each Expression in the returned Questionnaires has
        an Alternative Expression extension containing compiled JSON ELM.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-96'

      run do
        questionnaire_details = returned_questionnaires
        skip_if questionnaire_details.blank?, 'No Questionnaire resources were returned'

        cql_expressions = questionnaire_details.flat_map { |details| cql_questionnaire_expressions(details) }
        omit_if cql_expressions.blank?, 'No CQL expressions were found'

        expressions_without_elm = cql_expressions.reject do |details|
          alternative_expression_present?(details[:expression])
        end

        expressions_without_elm.each do |details|
          add_message(
            'error',
            "#{details[:location]} does not include an Alternative Expression extension with compiled JSON ELM."
          )
        end

        assert expressions_without_elm.blank?,
               'One or more CQL expressions did not include compiled JSON ELM. See messages for details.'
      end

      private

      def cql_questionnaire_expressions(details)
        questionnaire = details[:questionnaire]
        cql_expressions_from_extensions(questionnaire.extension, details, 'Questionnaire-level extension') +
          questionnaire_items(questionnaire).flat_map do |item|
            cql_expressions_from_extensions(item.extension, details, "linkId `#{item.linkId}`")
          end
      end

      def cql_expressions_from_extensions(extensions, details, location)
        extensions.flat_map do |extension|
          expressions = []
          if extension.valueExpression.present? && cql_expression?(extension.valueExpression)
            expressions << {
              expression: extension.valueExpression,
              location: "#{request_location(details)}, #{location}"
            }
          end
          expressions.concat(cql_expressions_from_extensions(extension.extension, details, location))
        end
      end

      def request_location(details)
        "#{details[:operation]} request #{details[:request_index] + 1}"
      end

      def alternative_expression_present?(expression)
        expression.extension.any? do |extension|
          extension.url == ALTERNATIVE_EXPRESSION_URL && extension.valueExpression&.expression.present?
        end
      end
    end
  end
end
