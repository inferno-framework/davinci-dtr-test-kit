require_relative 'dtr_questionnaire_response_save_test'
require_relative '../shared/dtr_questionnaire_response_basic_conformance_test'
require_relative '../shared/dtr_questionnaire_response_pre_population_test'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponseGroup < Inferno::TestGroup
    id :dtr_resp_response
    title 'Questionnaire Response'
    description %(
      Demonstrate the ability to pre-populate and respond to the Respiratory Assist Device Questionnaire.
    )
    run_as_group

    test from: :dtr_resp_questionnaire_response_save,
         receives_request: :questionnaire_response_save

    test from: :dtr_questionnaire_response_basic_conformance,
         uses_request: :questionnaire_response_save

    test from: :dtr_questionnaire_response_pre_population,
         uses_request: :questionnaire_response_save
  end
end
