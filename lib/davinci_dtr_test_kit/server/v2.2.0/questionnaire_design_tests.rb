# frozen_string_literal: true

require_relative '../../tags'
require_relative 'questionnaire_design_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module QuestionnaireDesignTest
      include QuestionnaireDesignValidation

      private

      def returned_questionnaires
        requests = load_tagged_requests(QUESTIONNAIRE_TAG) + load_tagged_requests(NEXT_TAG)
        questionnaires_from_requests(requests)
      end
    end

    class QuestionnaireRelevanceLogicTest < Inferno::Test
      include QuestionnaireDesignTest

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
        questionnaires = returned_questionnaires
        skip_if questionnaires.blank?, 'No Questionnaire resources were returned'

        assert questionnaires.any? { |questionnaire| questionnaire_has_relevance_logic?(questionnaire) },
               'No Questionnaire included enableWhen or enableWhenExpression relevance logic.'
      end
    end

    class QuestionnaireExpressionLanguageTest < Inferno::Test
      include QuestionnaireDesignTest

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

        non_cql_expressions = expressions.reject { |details| details[:expression].language == 'text/cql' }
        non_cql_details = non_cql_expressions.map do |details|
          "linkId `#{details[:link_id]}` (language `#{details[:expression].language || 'missing'}`)"
        end

        assert non_cql_expressions.blank?,
               "The following flow or rendering expressions were not written in CQL: #{non_cql_details.join(', ')}"
      end
    end

    class QuestionnairePrepopulationTest < Inferno::Test
      include QuestionnaireDesignTest

      id :dtr_v220_payer_questionnaire_prepopulation
      title 'Questionnaires support EHR prepopulation'
      description %(
        Inferno verifies that, across all Questionnaires returned by the DTR server,
        at least one includes logic supporting population from EHR data. Inferno looks
        for the SDC population extensions used by the previous version of this test.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-54'

      run do
        questionnaires = returned_questionnaires
        skip_if questionnaires.blank?, 'No Questionnaire resources were returned'

        assert questionnaires.any? { |questionnaire| questionnaire_has_prepopulation_logic?(questionnaire) },
               'No Questionnaire included logic supporting population from the EHR.'
      end
    end
  end
end