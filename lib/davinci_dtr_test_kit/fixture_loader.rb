require 'singleton'

module DaVinciDTRTestKit
  class FixtureLoader
    include Singleton

    attr_reader :questionnaire_package, :pre_populated_questionnaire_response

    def initialize
      qp_json = File.read('lib/davinci_dtr_test_kit/fixtures/questionnaire_package.json')
      @questionnaire_package = FHIR.from_contents(qp_json)

      qr_json = File.read('lib/davinci_dtr_test_kit/fixtures/pre_populated_questionnaire_response.json')
      @pre_populated_questionnaire_response = FHIR.from_contents(qr_json)
    end
  end
end
