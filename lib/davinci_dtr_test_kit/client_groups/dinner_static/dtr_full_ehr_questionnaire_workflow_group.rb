require_relative '../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_rendering_group'
require_relative 'dtr_full_ehr_store_attestation_test'
require_relative 'dtr_full_ehr_dinner_static_questionnaire_response_conformance_test'
require_relative 'dtr_full_ehr_dinner_static_questionnaire_response_correctness_test'

module DaVinciDTRTestKit
  class DTRFullEHRStaticDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_static_dinner_questionnaire_workflow
    title 'Static Questionnaire Workflow'
    description %(
      This test validates that a DTR Full EHR client can perform a full DTR Static Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate its ability to:

      1. Fetch the static questionnaire package
         ([DinnerOrderStatic](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_static/questionnaire_dinner_order_static.json))
      2. Render and pre-populate the questionnaire appropriately, including:
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled by other answers
      3. Complete and store the questionnaire response for future use.
    )

    group do
      id :dtr_full_ehr_static_questionnaire_retrieval
      title 'Retrieving the Static Questionnaire'
      description %(
        After DTR launch, Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and will return a static questionnaire for the
        tester to complete. Inferno will then validate the the conformance of the request.
      )
      run_as_group

      # Test 0: attest to launch
      test from: :dtr_full_ehr_launch_attestation
      # Test 1: wait for the $questionnaire-package request
      test from: :dtr_full_ehr_questionnaire_package_request
      # Test 2: validate the $questionnaire-package body
      test from: :dtr_questionnaire_package_request_validation
    end

    group from: :dtr_full_ehr_questionnaire_rendering

    group do
      id :dtr_full_ehr_static_questionnaire_response
      title 'Saving the QuestionnaireResponse'
      description %(
        The tester will attest to the completion of the questionnaire such that
        the results are stored for later use.
      )
      input :questionnaire_response,
            type: 'textarea',
            title: 'Completed QuestionnaireResponse',
            optional: true,
            description: %(
              The QuestionnaireResponse as exported from the EHR after completion of the Questionnaire. IMPORTANT: If
              you have not yet run the 'Filling Out the Static Questionnaire' group, leave this blank until you have
              done so. Then, run just the 'Saving the QuestionnaireResponse' group and populate this input.
            )
      run_as_group

      # Test 1: attest QuestionnaireResponse saved
      test from: :dtr_full_ehr_dinner_static_store_attestation
      # Test 2: verify basic conformance of the QuestionnaireResponse
      test from: :dtr_full_ehr_dinner_static_questionnaire_response_conformance
      # Test 3: check workflow-specific details such as pre-population and overrides
      test from: :dtr_full_ehr_dinner_static_questionnaire_response_correctness
    end
  end
end
