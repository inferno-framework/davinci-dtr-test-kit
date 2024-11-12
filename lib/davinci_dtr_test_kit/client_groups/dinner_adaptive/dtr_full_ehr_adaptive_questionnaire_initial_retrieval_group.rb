require_relative '../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative 'dtr_full_ehr_adaptive_questionnaire_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative 'dtr_adaptive_questionnaire_next_question_request_validation_test'
require_relative 'dtr_adaptive_questionnaire_response_validation_test'

module DaVinciDTRTestKit
  class DTRFullEHRAdaptiveQuestionnaireInitialRetrievalGroup < Inferno::TestGroup
    id :dtr_full_ehr_adaptive_questionnaire_initial_retrieval
    title 'Adaptive Questionnaire Package and Initial Questions Retrieval'

    run_as_group

    # Test 0: attest to launch
    test from: :dtr_full_ehr_launch_attestation
    # Test 1: wait for the $questionnaire-package request and initial $next-question request
    test from: :dtr_full_ehr_adaptive_questionnaire_request
    # Test 2: validate the $questionnaire-package request body
    test from: :dtr_questionnaire_package_request_validation
    # Test 3: validate the $next-question request body
    test from: :dtr_next_question_request_validation
    # Test 4: validate the QuestionnaireResponse in the input parameter
    test from: :dtr_adaptive_questionnaire_response_validation
  end
end
