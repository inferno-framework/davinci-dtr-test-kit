require_relative 'dtr_questionnaire_response_save_test'
require_relative 'dtr_questionnaire_response_pre_population_test'

module DaVinciDTRTestKit
  class DTRQuestionnairePrePopulationGroup < Inferno::TestGroup
    id :dtr_questionnaire_pre_population
    title 'Questionnaire Pre-population'
    description %(
      Demonstrate the ability to pre-populate a questionnaire.
    )
    run_as_group

    test from: :dtr_questionnaire_response_save,
         receives_request: :questionnaire_response_save

    test from: :dtr_questionnaire_response_pre_population,
         uses_request: :questionnaire_response_save
  end
end
