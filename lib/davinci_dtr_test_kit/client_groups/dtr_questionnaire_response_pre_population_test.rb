require_relative '../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponsePrePopulationTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_questionnaire_response_pre_population
    title 'QuestionnaireResponse pre-population is conformant'
    description %(
      This test validates the conformance of the client's pre-population of the QuestionnaireResponse.

      It verifies:

      1. The QuestionnaireResponse conforms to the DTR Questionnaire Response resource profile
      2. All items that should be pre-populated by CQL execution have an answer
      3. Pre-populated answers have origin.source set to either 'auto' or 'override'
      4. Answer for 'Last Name' is equal to its expected calculated value
      5. CQL Library dataRequirements have been fetched
      (to the extent this can be observed in the QuestionnaireResponse)
    )

    run do
      validate_questionnaire_pre_population(request)
    end
  end
end
