require_relative '../dtr_questionnaire_package_request_test'
require_relative '../dtr_questionnaire_package_request_validation_test'
require_relative 'prepopulation_attestation_test'
require_relative 'rendering_enabled_questions_attestation_test'
require_relative '../dtr_questionnaire_response_save_test'

module DaVinciDTRTestKit
  class DTRSmartAppStaticDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_static_dinner_questionnaire_workflow
    title 'Static Questionnaire Workflow'
    description %(
      This test validates that a DTR SMART App client can perform a full DTR Static Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate their ability to:

      1. Fetch the static questionnaire package
      2. Render and pre-populate the questionnaire appropriately, including:
         - fetch additional data needed for pre-population
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled
      3. Provide the completed QuestionnaireResponse with appropriate indicators for pre-populated
         and manually-entered data.
    )

    group do
      id :dtr_static_questionnaire_retrieval
      title 'Retrieving the Static Questionnaire'
      description %(
        Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and will return a static questionnaire for the
        tester to complete. Inferno will then validate the the conformance of the request.
      )
      run_as_group

      # Test 1: wait for the $questionnaire-package request
      test from: :dtr_questionnaire_package_request,
           receives_request: :questionnaire_package
      # Test 2: validate the $questionnaire-package body
      test from: :dtr_questionnaire_package_request_validation,
           uses_request: :questionnaire_package
    end

    group do
      id :dtr_static_questionnaire_rendering
      title 'Filling Out the Static Questionnaire'
      description %(
        The tester will interact with the questionnaire within their client system
        such that pre-population steps are taken, the qustionnaire is rendered, and
        they are able to fill it out. Inferno will check that appropriate interactions
        with the server occur and the tester will attest that questionnaire pre-population
        and rendering directives were followed.
      )
      run_as_group

      # Test 1: test to make sure they have requested encounter data
      # since the questionnaire asks them to
      # TODO: once Tom has gotten the reference implementation hooked up
      # Test 2: attest to the pre-population of the name fields, maybe the Encounter field as well
      test from: :dtr_dinner_static_rendering_prepopulation_attestation
      # Test 3: attest to the display of the toppings questions only when a dinner answer is selected
      test from: :dtr_dinner_static_rendering_enabledQs_attestation
    end

    group do
      id :dtr_static_questionnaire_response
      title 'Saving the QuestionnaireResponse'
      description %(
        The tester will complete the questionnaire such that a QuestionnaireResponse is stored
        back into Inferno's EHR endpoint. The stored QuestionnaireResponse will be evaluated for
        conformance, correct indicators on pre-populated and manually-overriden items.
      )
      run_as_group

      # Test 1: wait for a QuestionnaireResponse
      test from: :dtr_questionnaire_response_save,
           receives_request: :questionnaire_response_save
      # Test 2: validate the QuestionnaireResponse, including conformance, pre-population flags,
      # and any other details.
      test from: :dtr_questionnaire_response_pre_population,
           uses_request: :questionnaire_response_save
    end
  end
end
