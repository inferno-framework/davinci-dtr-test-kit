require_relative '../../dtr_questionnaire_response_validation'

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
      assert_valid_json(request.request_body)
      questionnaire_response = FHIR.from_contents(request.request_body)
      skip_if !questionnaire_response.present?, 'QuestionnaireResponse not received'

      validate_questionnaire_pre_population(questionnaire_response, id)
    end
  end
end
