require_relative '../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'

module DaVinciDTRTestKit
  class DTRFullEHRAdaptiveDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_adaptive_dinner_questionnaire_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This test validates that a DTR Full EHR client can perform a full DTR Adaptive Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate their ability to:

      1. Fetch the adaptive questionnaire package
        ([DinnerOrderAdaptive](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_adaptive/questionnaire_dinner_order_adaptive.json))
      2. Fetch the first set of questions and render and pre-populate them appropriately, including:
         - fetch additional data needed for pre-population
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled
      3. Answer the initial questions and request additional questions
      4. Complete the questionnaire and provide the completed QuestionnaireResponse
         with appropriate indicators for pre-populated and manually-entered data.
    )

    group do
      id :dtr_full_ehr_adaptive_questionnaire_retrieval
      title 'Retrieving the Adaptive Questionnaire'
      description %(
        After DTR launch, Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and will return an adaptive questionnaire for the tester to complete.
        Inferno will then validate the conformance of the request.
      )
      run_as_group

      # Test 0: attest to launch
      test from: :dtr_full_ehr_launch_attestation
      # Test 1: wait for the $questionnaire-package request
      test from: :dtr_full_ehr_questionnaire_package_request
      # Test 2: validate the $questionnaire-package request body
      test from: :dtr_questionnaire_package_request_validation
    end
  end
end
