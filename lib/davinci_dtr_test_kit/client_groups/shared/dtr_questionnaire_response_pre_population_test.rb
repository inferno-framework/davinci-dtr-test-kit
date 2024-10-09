# frozen_string_literal: true

require_relative '../../dtr_questionnaire_response_validation'
require_relative '../../fixtures'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponsePrePopulationTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_questionnaire_response_pre_population
    title 'QuestionnaireResponse pre-population and user overrides are conformant'
    description %(
      This test validates the conformance of the client's pre-population of the QuestionnaireResponse.

      It verifies:

      1. All items that should be pre-populated by CQL execution have an answer
      2. Pre-populated answers the tester was not directed to override have
         the origin.source extension set to 'auto' and an answer equivalent to
         from the expected result from execution of the CQL on Inferno's data.
      3. Pre-populated answers the tester was directed to override have
         the origin.source extension set to 'override' and an answer different
         from the expected result from execution of the CQL on Inferno's data.
    )

    run do
      questionnaire_response_json = request.request_body
      check_is_questionnaire_response(questionnaire_response_json)
      questionnaire_response = FHIR.from_contents(questionnaire_response_json)
      questionnaire = Fixtures.questionnaire_for_test(id)
      response_template = Fixtures.questionnaire_response_for_test(id)
      validate_questionnaire_pre_population(questionnaire, response_template, questionnaire_response)
    end
  end
end
