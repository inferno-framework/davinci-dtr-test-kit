require_relative '../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../shared/dtr_custom_questionnaire_libraries_test'
require_relative '../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../shared/dtr_custom_questionnaire_expressions_test'
require_relative '../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'

module DaVinciDTRTestKit
  class DTRFullEHRCustomStaticRetrievalGroup < Inferno::TestGroup
    id :dtr_full_ehr_custom_static_retrieval
    title 'Retrieving the Static Questionnaire'
    description %(
      During this test, DTR will be launch in the Full EHR to start the demonstration of
      static Questionnaire capabilities. This launch must occur within the context of a patient
      that will demonstrate the Questionnaire's pre-population logic. The patient's data needs
      to support pre-population of at least two answers to allow for demonstration of both
      pre-populated and manually-overridden answers in the resulting QuestionnaireResponse.

      After DTR launch, Inferno will wait for the client system to request a questionnaire using the
      $questionnaire-package operation and will return a static questionnaire for the
      tester to complete. Inferno will then validate the the conformance of the request
      and of the provided Questionnaire that Inferno responded with.
    )
    run_as_group

    input_order :access_token, :custom_questionnaire_package_response

    # Test 0: attest to launch
    test from: :dtr_full_ehr_launch_attest,
         config: { options: { attestation_message:
            'I attest that DTR has been launched in the context of a patient with data that will exercise pre-population logic in the provided static questionnaire resulting in at least 2 pre-populated answers.' } }, # rubocop:disable Layout/LineLength
         title: 'Launch DTR (Attestation)'
    # Test 1: wait for the $questionnaire-package request
    test from: :dtr_full_ehr_qp_request do
      input :custom_questionnaire_package_response
    end
    # Test 2: validate the $questionnaire-package body
    test from: :dtr_qp_request_validation
    # Test 3: validate the user provided $questionnaire-package response
    test from: :dtr_custom_qp_validation
    # Test 4: verify the custom response has the necessary libraries for pre-population
    test from: :dtr_custom_questionnaire_libraries
    # Test 5: verify the custom response has the necessary extensions for pre-population
    test from: :dtr_custom_questionnaire_extensions
    # Test 6: verify custom response has necessary expressions for pre-population
    test from: :dtr_custom_questionnaire_expressions
  end
end
