require_relative 'fixture_loader'

module DaVinciDTRTestKit
  module Fixtures
    def standard_questionnaire_package
      @standard_questionnaire_package ||= FixtureLoader.instance.standard_questionnaire_package
    end

    def standard_questionnaire
      @standard_questionnaire ||= standard_questionnaire_package.parameter.first.resource.entry.find do |e|
        e.resource.is_a?(FHIR::Questionnaire)
      end.resource
    end
  end
end
