require_relative 'dtr_smart_app_questionnaire_response_save_test'
require_relative '../shared/dtr_questionnaire_response_basic_conformance_test'

module DaVinciDTRTestKit
  class DTRSmartAppSavingQuestionnaireResponseGroup < Inferno::TestGroup
    id :dtr_smart_app_saving_qr
    title 'Saving the QuestionnaireResponse'
    description %(
      The tester will complete the questionnaire such that a QuestionnaireResponse is stored
      back into Inferno's EHR endpoint. The stored QuestionnaireResponse will be evaluated for
      conformance, completeness, and correct indicators on pre-populated and manually-overriden
      items.
    )
    run_as_group

    # Test 1: wait for a QuestionnaireResponse
    test from: :dtr_smart_app_qr_save,
         receives_request: :questionnaire_response_save
    # Test 2: validate basic conformance of the QuestionnaireResponse
    test from: :dtr_qr_basic_conformance,
         uses_request: :questionnaire_response_save
  end
end
