require 'singleton'
require 'fhir_models'

module DaVinciDTRTestKit
  class FixtureLoader
    include Singleton

    attr_reader :questionnaire_package

    def initialize
      @questionnaire_package = init_questionnaire_package_and_response('lib/davinci_dtr_test_kit/fixtures/questionnaire_package.json')

      # list of lists
      # - first entry is the path to a file containing a Questionnaire Bundle (not Parameters)
      # - second entry is the path to a file containing a Populated QuestionnaireResponse
      #   for use in validation.
      # - third entry is a list of group id within which this questionnaire should be used and
      #   will be returned for any $questionnaire-package calls. This association of a questionnaire
      #   with a specific test is Inferno's simulated version of payer business logic.
      questionnaires_to_load =
        [
          [
            'lib/davinci_dtr_test_kit/fixtures/questionnaire_package.json',
            'lib/davinci_dtr_test_kit/fixtures/pre_populated_questionnaire_response.json',
            ['dtr_smart_app_questionnaire_workflow', 'dtr_full_ehr_questionnaire_workflow']
          ],
          [
            'lib/davinci_dtr_test_kit/fixtures/dinner_static/questionnaire_dinner_order_static.json',
            '',
            ['dtr_smart_app_static_dinner_questionnaire_workflow']
          ],
          [
            'lib/davinci_dtr_test_kit/fixtures/dinner_adaptive/questionnaire_dinner_order_adaptive.json',
            '',
            ['dtr_smart_app_adaptive_dinner_questionnaire_workflow']
          ]
        ]

      questionnaires_to_load.each do |questionnaire_details|
        init_questionnaire_package_and_response(questionnaire_details[0], questionnaire_details[1], questionnaire_details[2])
      end
    end

    def canonical_to_questionnaire_package_map
      @canonical_to_questionnaire_package_map ||= {}
    end

    def questionnaire_package_for_canonical(url)
      @canonical_to_questionnaire_package_map[url]
    end

    def group_id_to_questionnaire_canonical_map
      @group_id_to_questionnaire_canonical_map ||= {}
    end

    def questionnaire_canonical_for_group_id(group_id)
      group_id_to_questionnaire_canonical_map[group_id]
    end

    def questionnaire_package_for_group_id(group_id)
      canonical = questionnaire_canonical_for_group_id(group_id)
      return unless canonical

      @canonical_to_questionnaire_package_map[canonical]
    end

    def group_id_to_questionnaire_response_map
      @group_id_to_questionnaire_response_map ||= {}
    end

    def questionnaire_response_for_group_id(group_id)
      group_id_to_questionnaire_response_map[group_id]
    end

    def init_questionnaire_package_and_response(package_file, response_file = nil, covered_groups = nil)
      package_json = File.read(package_file)
      package = FHIR.from_contents(package_json)
      url = get_url_for_questionnaire(package)

      canonical_to_questionnaire_package_map[url] = package if url
      covered_groups&.each do |group|
        group_id_to_questionnaire_canonical_map[group] = url
      end

      if response_file.present?
        response_json = File.read(response_file)
        response = FHIR.from_contents(response_json)

        covered_groups&.each do |group|
          group_id_to_questionnaire_response_map[group] = response
        end

      end

      package
    end

    def get_url_for_questionnaire(questionnaire_bundle_or_package)
      case questionnaire_bundle_or_package
      when FHIR::Questionnaire
        questionnaire_bundle_or_package.url
      when FHIR::Bundle
        # assumes questionnaire is the first entry per requirement
        get_url_for_questionnaire(questionnaire_bundle_or_package.entry[0].resource)
      when FHIR::Parameters
        # assumes return is the first parameter
        get_url_for_questionnaire(questionnaire_bundle_or_package.parameter[0].resource)
      end
    end
  end
end
