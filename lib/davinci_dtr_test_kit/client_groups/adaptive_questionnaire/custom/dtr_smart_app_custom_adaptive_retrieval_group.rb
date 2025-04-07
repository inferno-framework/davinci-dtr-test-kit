require_relative 'dtr_smart_app_custom_adaptive_request_test'
require_relative '../../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../dtr_adaptive_next_question_request_validation_test'
require_relative '../dtr_adaptive_response_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../../shared/dtr_custom_questionnaire_libraries_test'
require_relative '../../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../../shared/dtr_custom_questionnaire_expressions_test'
require_relative 'dtr_custom_next_question_response_validation_test'

module DaVinciDTRTestKit
  class DTRSmartAppCustomAdaptiveRetrievalGroup < Inferno::TestGroup
    id :dtr_smart_app_custom_adaptive_retrieval
    title 'Retrieving the Adaptive Questionnaire'

    # Test 1: wait for the $questionnaire-package request and initial $next-question request
    test from: :dtr_smart_app_custom_adative_request
    # Test 2: validate the $questionnaire-package request body
    test from: :dtr_qp_request_validation
    # Test 3: validate the $next-question request body
    test from: :dtr_adaptive_next_question_request_validation
    # Test 4: validate the QuestionnaireResponse in the input parameter
    test from: :dtr_adaptive_response_validation do
      description %(
        Verify that all submitted QuestionnaireResponse resources meet the following criteria:
        - Conform to the [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt).
        - Include source extensions indicating whether answers were manually entered,
          automatically pre-populated, or manually overridden (for `completed` QuestionnaireResponse).
        - Provide answers for all required items in their contained Questionnaire.
      )
      input :custom_next_question_questionnaires
    end
    # Test 5: validate the user provided $questionnaire-package response
    test from: :dtr_custom_qp_validation
    # Test 6: verify the custom response has the necessary libraries for pre-population
    test from: :dtr_custom_questionnaire_libraries
    # Test 7: validate the user provided $next-question questionnaire
    test from: :dtr_custom_next_questionnaire_validation
    # Test 8: verify the custom response has the necessaru extensions for pre-population
    test from: :dtr_custom_questionnaire_extensions do
      title %(
        [USER INPUT VERIFICATION] Custom Questionnaires for $next-question Responses contain extensions
        necessary for pre-population
      )
      input :custom_next_question_questionnaires
    end
    # Test 9: verify custom response has necessary expressions for pre-population
    test from: :dtr_custom_questionnaire_expressions do
      title %(
        [USER INPUT VERIFICATION] Custom Questionnaires for $next-question Responses contain items with
        expressions necessary for pre-population
      )
      input :custom_next_question_questionnaires
    end
  end
end
