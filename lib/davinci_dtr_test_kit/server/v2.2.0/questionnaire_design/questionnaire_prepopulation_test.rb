# frozen_string_literal: true

require_relative 'questionnaire_design_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnairePrepopulationTest < Inferno::Test
      include QuestionnaireDesignValidation

      POPULATION_EXPRESSION_URLS = [
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression'
      ].freeze

      id :dtr_v220_payer_questionnaire_prepopulation
      title 'Questionnaires support EHR prepopulation'
      description %(
        Inferno verifies that, across all Questionnaires returned by the DTR server,
        at least one includes an extension indicating support for population from
        EHR data.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-54'

      run do
        questionnaires = returned_questionnaires
        skip_if questionnaires.blank?, 'No Questionnaire resources were returned'

        assert questionnaires.any? { |questionnaire| questionnaire_has_prepopulation_logic?(questionnaire) },
               'No Questionnaire included logic supporting population from the EHR.'
      end

      private

      def questionnaire_has_prepopulation_logic?(questionnaire)
        questionnaire_items(questionnaire).any? do |item|
          item.extension.any? { |extension| POPULATION_EXPRESSION_URLS.include?(extension.url) }
        end
      end
    end
  end
end