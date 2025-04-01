require_relative '../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../shared/dtr_custom_questionnaire_libraries_test'
require_relative '../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../shared/dtr_custom_questionnaire_expressions_test'
require_relative '../smart_app/dtr_smart_app_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'

module DaVinciDTRTestKit
  class DTRSmartAppCustomStaticRetrievalGroup < Inferno::TestGroup
    id :dtr_smart_app_custom_static_retrieval
    title 'Retrieving the Static Questionnaire'
    description %(
      During this test, DTR will be launch in the SMART App client to start the demonstration of
      static Questionnaire capabilities. This launch must occur within the context of a patient
      that will demonstrate the Questionnaire's pre-population logic. The patient's data needs
      to support pre-population of at least two answers to allow for demonstration of both
      pre-populated and manually-overridden answers in the resulting QuestionnaireResponse.

      After DTR launch, Inferno will wait for the client system to request a questionnaire using the
      $questionnaire-package operation and will return a static questionnaire for the
      tester to complete. Inferno will then validate the conformance of the request
      and of the provided Questionnaire that Inferno responded with.
    )
    run_as_group

    # Test 1: wait for the $questionnaire-package request
    test from: :dtr_smart_app_qp_request do
      input :custom_questionnaire_package_response
    end
    # Test 2: validate the $questionnaire-package body
    test from: :dtr_qp_request_validation
    # Test 3: validate the user provided $questionnaire-package response
    test from: :dtr_custom_qp_validation
    # Test 4: verify the custom response has the necessary libraries for pre-population
    test from: :dtr_custom_questionnaire_libraries
    # Test 5: verify the custom response has the necessaru extensions for pre-population
    test from: :dtr_custom_questionnaire_extensions
    # Test 6: verify custom response has necessary expressions for pre-population
    test from: :dtr_custom_questionnaire_expressions
  end
end
