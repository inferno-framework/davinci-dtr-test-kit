require_relative 'fixture_loader'

module DaVinciDTRTestKit
  module Fixtures
    AUTO_POPULATED_ANSWERS = { 'Last Name' => 'PBD.1' }.freeze
    DATA_REQUIREMENT_ANSWERS = { 'RAD Prepopulation' => '3.1' }.freeze

    def questionnaire_package
      @questionnaire_package ||= FixtureLoader.instance.questionnaire_package
    end

    def questionnaire
      @questionnaire ||= questionnaire_package.parameter.first.resource.entry.find do |e|
        e.resource.is_a?(FHIR::Questionnaire)
      end.resource
    end

    def pre_populated_questionnaire_response
      @pre_populated_questionnaire_response ||=
        FixtureLoader.instance.pre_populated_questionnaire_response
    end
  end
end
