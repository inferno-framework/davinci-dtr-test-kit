# frozen_string_literal: true

require_relative 'questionnaire_design_support'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireRelevanceLogicTest < Inferno::Test
      include QuestionnaireDesignSupport

      ENABLE_WHEN_EXPRESSION_URL =
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression'

      id :dtr_v220_payer_questionnaire_relevance_logic
      title 'Questionnaires include relevance logic'
      description %(
        Inferno verifies that, across all Questionnaires returned by the DTR server, at
        least one demonstrates logic for including only relevant questions and answer
        choices based on answers already provided, using `enableWhen` or
        `enableWhenExpression`.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-17'

      run do
        questionnaires = returned_questionnaires.map { |details| details[:questionnaire] }
        skip_if questionnaires.blank?, 'No Questionnaire resources were returned'

        assert questionnaires.any? { |questionnaire| questionnaire_has_relevance_logic?(questionnaire) },
               'No Questionnaire included enableWhen or enableWhenExpression relevance logic.'
      end

      private

      def questionnaire_has_relevance_logic?(questionnaire)
        questionnaire_items(questionnaire).any? do |item|
          item.enableWhen.present? || item.extension.any? { |extension| extension.url == ENABLE_WHEN_EXPRESSION_URL }
        end
      end
    end
  end
end
