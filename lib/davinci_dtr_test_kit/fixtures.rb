require_relative 'fixture_loader'

module DaVinciDTRTestKit
  module Fixtures
    DATA_REQUIREMENT_ANSWERS = { 'RAD Prepopulation' => '3.1' }.freeze

    def get_questionnaire_package_for_group_id(group_id)
      FixtureLoader.instance.questionnaire_package_for_group_id(group_id)
    end

    def find_questionnaire_instance_for_test_id(test_id)
      canonical_url = find_questionnaire_canonical_for_test_id(test_id)
      return unless canonical_url.present?

      package = get_questionnaire_packcage_for_canonical(canonical_url)
      return unless package.present?

      questionnaire = nil
      package.entry.find do |entry|
        questionnaire = entry.resource if entry.resource.is_a?(FHIR::Questionnaire)
      end
      questionnaire
    end

    def find_questionnaire_canonical_for_test_id(test_id)
      canonical_url = nil

      # test_id is of the form [suite id]-[group id 1]-...-[group id n]-[test id]
      groups = test_id.split('-')[1..-2] # first is suite, last is test, we want groups
      groups.each do |one_group_id|
        next if canonical_url.present?

        canonical_url = get_questionnaire_canonical_for_group_id(one_group_id)
      end

      canonical_url
    end

    def get_questionnaire_canonical_for_group_id(group_id)
      FixtureLoader.instance.questionnaire_canonical_for_group_id(group_id)
    end

    def get_questionnaire_packcage_for_canonical(url)
      FixtureLoader.instance.questionnaire_package_for_canonical(url)
    end

    def find_questionnaire_response_for_test_id(test_id)
      questionnaire_response = nil

      # test_id is of the form [suite id]-[group id 1]-...-[group id n]-[test id]
      groups = test_id.split('-')[1..-2] # first is suite, last is test, we want groups
      groups.each do |one_group_id|
        next if questionnaire_response.present?

        questionnaire_response = get_questionnaire_response_for_group_id(one_group_id)
      end

      questionnaire_response
    end

    def get_questionnaire_response_for_group_id(group_id)
      FixtureLoader.instance.questionnaire_response_for_group_id(group_id)
    end
  end
end
