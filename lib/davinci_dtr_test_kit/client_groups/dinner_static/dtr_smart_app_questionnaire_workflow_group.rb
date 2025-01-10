require_relative 'dtr_smart_app_dinner_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../shared/dtr_prepopulation_attestation_test'
require_relative '../shared/dtr_rendering_enabled_questions_attestation_test'
require_relative '../shared/dtr_prepopulation_override_attestation_test'
require_relative '../smart_app/dtr_smart_app_saving_questionnaire_response_group'
require_relative '../smart_app/dtr_smart_app_questionnaire_response_correctness_test'
require_relative 'dtr_custom_questionnaire_package_validation_test'
require_relative 'dtr_custom_questionnaire_libraries_test'
require_relative 'dtr_custom_questionnaire_extensions_test'
require_relative 'dtr_custom_questionnaire_expressions_test'

module DaVinciDTRTestKit
  class DTRSmartAppStaticDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_static_dinner_questionnaire_workflow
    title 'Static Questionnaire Workflow'
    description %(
      This test validates that a DTR SMART App client can perform a full DTR Static Questionnaire workflow.
      Users have the option to either use a mocked questionnaire requesting what a patient wants for dinner
      or provide a custom questionnaire package of their choice for the test. The client system must
      demonstrate its ability to:

      1. Fetch the static questionnaire package
         ([DinnerOrderStatic](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/dinner_static/questionnaire_dinner_order_static.json))
         or the custom questionnaire package
      2. Render and pre-populate the questionnaire appropriately, including:
         - fetch additional data needed for pre-population
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled by other answers
      3. Provide the completed QuestionnaireResponse with appropriate indicators for pre-populated
         and manually-entered data.
    )

    group do
      id :dtr_smart_app_static_questionnaire_retrieval
      title 'Retrieving the Static Questionnaire'
      description %(
        Inferno will wait for the client system to request a questionnaire using the
        $questionnaire-package operation and will return a static questionnaire for the
        tester to complete. Inferno will then validate the conformance of the request.
      )
      run_as_group

      def retrieval_method
        'Static'
      end

      # Test 1: validate the user provided $questionnaire-package response
      test from: :dtr_custom_questionnaire_package_validation
      # Test 2: verify the custom response has the necessary libraries for pre-population
      test from: :dtr_custom_questionnaire_libraries
      # Test 3: verify the custom response has the necessaru extensions for pre-population
      test from: :dtr_custom_questionnaire_extensions
      # Test 4: verify custom response has necessary expressions for pre-population
      test from: :dtr_custom_questionnaire_expressions
      # Test 5: wait for the $questionnaire-package request
      test from: :dtr_smart_app_dinner_questionnaire_package_request
      # Test 6: validate the $questionnaire-package body
      test from: :dtr_questionnaire_package_request_validation
    end

    group do
      id :dtr_smart_app_static_questionnaire_rendering
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
      # TODO: once Tom has gotten the reference server hooked up
      # Test 2: attest to the pre-population of the name fields
      test from: :dtr_prepopulation_attestation
      # Test 3: attest to the pre-population and edit of the location field
      test from: :dtr_prepopulation_override_attestation
      # Test 4: attest to proper display of enabled question(s)
      test from: :dtr_rendering_enabled_questions_attestation
    end

    group from: :dtr_smart_app_saving_questionnaire_response do
      test from: :dtr_smart_app_qr_correctness,
           uses_request: :questionnaire_response_save
    end
  end
end
