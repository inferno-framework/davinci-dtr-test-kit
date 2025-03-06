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
      if respond_to?(:custom_next_question_questionnaire)
        omit_if custom_next_question_questionnaire.blank?,
                'Next question or set of questions not provided for this round'
      end

      questionnaires = nil
      if form_type == 'static'
        skip_if scratch[:"#{form_type}_questionnaire_bundles"].blank?,
                'No questionnaire bundle found in the custom response'
        questionnaires = extract_questionnaires_from_bundles(scratch[:"#{form_type}_questionnaire_bundles"])
      else
        assert_valid_json custom_next_question_questionnaire, 'Custom $next-question Questionnaire is not valid JSON'
        # This is necessary for adaptive Q to retrieve and save libraries in memory
        if try(:custom_questionnaire_package_response)
          skip_if custom_questionnaire_package_response.blank?, 'Need to provide questionnaire package bundle input.'
          assert_valid_json custom_questionnaire_package_response,
                            'Custom package response provided is not a valid JSON'
          resource = FHIR.from_contents(custom_questionnaire_package_response)
          questionnaire_bundles = extract_questionnaire_bundles(resource)
          check_libraries(questionnaire_bundles)
        end
        questionnaires = [FHIR.from_contents(custom_next_question_questionnaire)].compact
      end

      verify_questionnaire_extensions(questionnaires)
    end
  end
end
