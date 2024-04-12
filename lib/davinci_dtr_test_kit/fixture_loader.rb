require 'singleton'

module DaVinciDTRTestKit
  class FixtureLoader
    include Singleton

    attr_reader :standard_questionnaire_package

    def initialize
      questionnaire_package_json = File.read('lib/davinci_dtr_test_kit/fixtures/standard_questionnaire_package.json')
      @standard_questionnaire_package = FHIR.from_contents(questionnaire_package_json)
    end
  end
end
