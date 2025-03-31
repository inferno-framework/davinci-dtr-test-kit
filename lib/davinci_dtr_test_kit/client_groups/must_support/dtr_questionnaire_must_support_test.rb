require_relative '../../cql_test'

module DaVinciDTRTestKit
  class DTRQuestionnaireMustSupportTes < Inferno::Test
    include DaVinciDTRTestKit::CQLTest
    id :dtr_questionnaire_must_support

    config(options: { debug_must_support_metadata: true })

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
                'No questionnaire bundle found in the custom response'

        questionnaires = extract_questionnaires_from_bundles(scratch[:"#{form_type}_questionnaire_bundles"])
      else
        assert_valid_json custom_next_question_questionnaires,
                          'Custom $next-question questionnairee not valid JSON'
        custom_questionnaires = [JSON.parse(custom_next_question_questionnaires)].flatten.compact
        questionnaires = custom_questionnaires.map { |q| FHIR.from_contents(q.to_json) }.compact
      end

      skip_if questionnaires.blank? || questionnaires.none? { |q| q.is_a?(FHIR::Questionnaire) },
              'No Questionnaire resources found.'

      # this raises Error: 404 Not Found when attempting to download IG using this url:
      # https://packages.fhir.org/hl7.fhir.us.davinci-dtr/-/hl7.fhir.us.davinci-dtr-2.0.1.tgz
      # Not sure if `"https://packages.fhir.org/#{package_name}/-/#{package_name}-#{version}.tgz"`
      # in the IgDownloader#ig_registry_url method is the correct uri pattern to determine the
      # package url for all IGs. Need to check with Dylan
      skip { assert_must_support_elements_present(questionnaires, profile_url) }
    end
  end
end
