require_relative '../../../tags'
require_relative '../tests/dtr_smart_app_adaptive_request_test'
require_relative '../../../full_ehr/v2.0.1/shared/dtr_questionnaire_package_request_validation_test'
require_relative '../../../full_ehr/v2.0.1/adaptive_interaction/dtr_adaptive_next_question_request_validation_test'
require_relative '../../../full_ehr/v2.0.1/adaptive_interaction/dtr_adaptive_response_validation_test'

module DaVinciDTRTestKit
  class DTRSmartAppAdaptiveInitialRetrievalGroup < Inferno::TestGroup
    id :dtr_smart_app_adaptive_initial_retrieval
    title 'Adaptive Questionnaire Package and Initial Questions Retrieval'

    config(options: { next_tag: "initial_#{CLIENT_NEXT_TAG}" })
    run_as_group

    # Test 1: wait for the $questionnaire-package request and initial $next-question request
    test from: :dtr_smart_app_adaptive_request
    # Test 2: validate the $questionnaire-package request body
    test from: :dtr_qp_request_validation
    # Test 3: validate the $next-question request body
    test from: :dtr_adaptive_next_question_request_validation
    # Test 4: validate the QuestionnaireResponse in the input parameter
    test from: :dtr_adaptive_response_validation
  end
end
