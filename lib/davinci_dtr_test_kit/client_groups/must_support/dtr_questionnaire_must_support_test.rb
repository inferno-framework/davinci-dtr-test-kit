require_relative '../../cql_test'

module DaVinciDTRTestKit
  class DTRQuestionnaireMustSupportTes < Inferno::Test
    include DaVinciDTRTestKit::CQLTest
    id :dtr_questionnaire_must_support
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@15', 'hl7.fhir.us.davinci-dtr_2.0.1@65',
                          'hl7.fhir.us.davinci-dtr_2.0.1@66', 'hl7.fhir.us.davinci-dtr_2.0.1@206'

    def form_type
      config.options[:form_type] || 'static'
    end

    def profile_url
      if form_type == 'adaptive'
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt'
      else
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire'
      end
    end

    run do
      questionnaires = nil
      if form_type == 'static'
        skip_if scratch[:"#{form_type}_questionnaire_bundles"].blank?,
                'No questionnaire bundle found in the custom Questionnaire Package response'

        questionnaires = extract_questionnaires_from_bundles(scratch[:"#{form_type}_questionnaire_bundles"])
      else
        assert_valid_json custom_next_question_questionnaires,
                          'Custom $next-question questionnaires not valid JSON'
        custom_questionnaires = [JSON.parse(custom_next_question_questionnaires)].flatten.compact
        questionnaires = custom_questionnaires.map { |q| FHIR.from_contents(q.to_json) }.compact
      end

      skip_if questionnaires.blank? || questionnaires.none? { |q| q.is_a?(FHIR::Questionnaire) },
              'No Questionnaire resources found.'

      skip { assert_must_support_elements_present(questionnaires, profile_url) }
    end
  end
end
