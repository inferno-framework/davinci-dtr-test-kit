require_relative 'fixture_loader'

module DaVinciDTRTestKit
  module Fixtures
    # Ideally the groups and/or tests would define which fixtures they use and this module would simply be a provider
    # of whatever fixture is requested. But the MockPayer needs to determine which questionnaire package belongs to
    # each group, so this is a straighforward way to facilitate that.
    FIXTURE_CONFIG = [
      {
        group_ids: [
          'dtr_smart_app_questionnaire_workflow',
          'dtr_full_ehr_questionnaire_workflow'
        ],
        questionnaire_package: File.join('respiratory_assist_device', 'questionnaire_package.json'),
        questionnaire_response: File.join('respiratory_assist_device', 'pre_populated_questionnaire_response.json')
      },
      {
        group_ids: [
          'dtr_smart_app_static_dinner_questionnaire_workflow',
          'dtr_full_ehr_static_dinner_questionnaire_workflow'
        ],
        questionnaire_package: File.join('dinner_static', 'questionnaire_dinner_order_static.json'),
        questionnaire_response: File.join('dinner_static', 'questionnaire_response_dinner_order_static.json')
      }
    ].freeze

    extend self

    # full_test_id needs to be the long inferno-generated ID that includes hyphenated ancestor IDs
    def questionnaire_package_for_test(full_test_id)
      get_fixture(full_test_id, :questionnaire_package)
    end

    # full_test_id needs to be the long inferno-generated ID that includes hyphenated ancestor IDs
    def questionnaire_response_for_test(full_test_id)
      get_fixture(full_test_id, :questionnaire_response)
    end

    # full_test_id needs to be the long inferno-generated ID that includes hyphenated ancestor IDs
    def questionnaire_for_test(full_test_id)
      questionnaire_package_for_test(full_test_id)&.entry&.find { |e| e.resource.is_a?(FHIR::Questionnaire) }&.resource
    end

    private

    def get_fixture(full_test_id, fixture_type)
      fixture_path = extract_group_ids(full_test_id).filter_map do |group_id|
        FIXTURE_CONFIG.find { |fc| fc[:group_ids].include?(group_id) }&.dig(fixture_type)
      end&.first

      FixtureLoader.instance[fixture_path]
    end

    # full_test_id is of the form [suite id]-[group id 1]-...-[group id n]-[test id]
    def extract_group_ids(full_test_id)
      # First is suite, last is test, we want groups
      full_test_id.split('-')[1...-1]&.reverse
    end
  end
end
