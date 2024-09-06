require_relative 'dtr_full_ehr_launch_attestation_test'
require_relative 'dtr_full_ehr_dinner_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative 'dtr_full_ehr_prepopulation_attestation_test'
require_relative 'dtr_full_ehr_prepopulation_override_attestation_test'
require_relative 'dtr_full_ehr_rendering_enabled_questions_attestation_test'
require_relative 'dtr_full_ehr_store_attestation_test'
require_relative 'dtr_full_ehr_prepopulation_representation_attestation_test'

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
      test from: :dtr_full_ehr_dinner_static_launch_attestation
      # Test 1: wait for the $questionnaire-package request
      test from: :dtr_full_ehr_dinner_questionnaire_package_request
      # Test 2: validate the $questionnaire-package body
      test from: :dtr_questionnaire_package_request_validation
    end

    group do
      id :dtr_full_ehr_static_questionnaire_rendering
      title 'Filling Out the Static Questionnaire'
      description %(
        The tester will interact with the questionnaire within their client system
        such that pre-population steps are taken, the qustionnaire is rendered, and
        they are able to fill it out. The tester will attest that questionnaire pre-population
        and rendering directives were followed.
      )
      run_as_group

      # Test 1: attest to the pre-population of the name fields
      test from: :dtr_full_ehr_dinner_static_rendering_prepopulation_attestation
      # Test 2: attest to the pre-population and edit of the first name field
      test from: :dtr_full_ehr_dinner_static_prepopulation_override_attestation
      # Test 3: attest to the display of the toppings questions only when a dinner answer is selected
      test from: :dtr_full_ehr_dinner_static_rendering_enabledQs_attestation
    end

    group do
      id :dtr_full_ehr_static_questionnaire_response
      title 'Saving the QuestionnaireResponse'
      description %(
        The tester will attest to the completion of the questionnaire such that
        the results are stored for later use.
      )
      run_as_group

      # Test 1: attest QuestionnaireResponse saved
      test from: :dtr_full_ehr_dinner_static_store_attestation
      # Test 2: validate basic conformance of the QuestionnaireResponse
      # - not using currently
      # Test 3: validate workflow-specific details such as pre-population and overrides
      test from: :dtr_full_ehr_dinner_static_prepopulation_representation_attestation
    end
  end
end
