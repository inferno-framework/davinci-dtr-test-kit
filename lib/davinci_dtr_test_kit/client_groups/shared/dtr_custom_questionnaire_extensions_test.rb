require_relative '../../cql_test'
module DaVinciDTRTestKit
  class DTRCustomQuestionnaireExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_custom_questionnaire_extensions
    title '[USER INPUT VERIFICATION] Custom questionnaire(s) contain extensions necessary for pre-population'
    description %(
      Inferno checks that the custom response has appropriate extensions and references to libraries within
      those extensions.
    )

    def form_type
      config.options[:form_type] || 'static'
    end

    run do
      questionnaires = nil
      if form_type == 'static'
        skip_if scratch[:"#{form_type}_questionnaire_bundles"].blank?,
                'No questionnaire bundle found in the custom package response'
        questionnaires = extract_questionnaires_from_bundles(scratch[:"#{form_type}_questionnaire_bundles"])
      else
        assert_valid_json custom_next_question_questionnaires, 'Custom $next-question questionnaires not valid JSON'
        custom_questionnaires = [JSON.parse(custom_next_question_questionnaires)].flatten.compact
        questionnaires = custom_questionnaires.map { |q| FHIR.from_contents(q.to_json) }.compact
      end

      verify_questionnaire_extensions(questionnaires)
    end
  end
end
