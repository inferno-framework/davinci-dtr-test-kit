require_relative '../../cql_test'
module DaVinciDTRTestKit
  class DTRCustomQuestionnaireExpressionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_custom_questionnaire_expressions
    title %(
      [USER INPUT VERIFICATION] Custom questionnaire(s) contain items with expressions
      necessary for pre-population
    )
    description %(
      Inferno checks that the custom response has appropriate expressions and that expressions are
      written in cql.
    )

    def form_type
      config.options[:form_type] || 'static'
    end

    run do
      questionnaires = nil
      if form_type == 'static'
        skip_if scratch[:"#{form_type}_questionnaire_bundles"].blank?,
                'No questionnaire bundle found in the custom response'

        questionnaires = extract_questionnaires_from_bundles(scratch[:"#{form_type}_questionnaire_bundles"])
      else
        assert_valid_json custom_next_question_questionnaire, 'Custom $next-question Questionnaire is not valid JSON'
        questionnaires = [FHIR.from_contents(custom_next_question_questionnaire)].compact
      end

      verify_questionnaire_items(questionnaires, final_cql_test: true)
    end
  end
end
