require_relative 'dtr_custom_questionnaire_package_validation_test'
require_relative 'dtr_custom_questionnaire_libraries_test'
require_relative 'dtr_custom_questionnaire_extensions_test'
require_relative 'dtr_custom_questionnaire_expressions_test'
require_relative '../smart_app/dtr_smart_app_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../shared/dtr_prepopulation_attestation_test'
require_relative '../shared/dtr_rendering_attestation_test'
require_relative '../shared/dtr_prepopulation_override_attestation_test'
require_relative '../smart_app/dtr_smart_app_saving_questionnaire_response_group'
require_relative '../smart_app/dtr_smart_app_questionnaire_response_correctness_test'

module DaVinciDTRTestKit
  class DTRSmartAppCustomStaticWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_custom_static_workflow
    title 'Static Questionnaire Workflow'
    description %(
      This group validates that a DTR SMART App client  can perform a full DTR Static Questionnaire workflow.
      Testers will provide a custom Questionnaire package of their choice for the test and
      will request and complete the Questionnaire in the context of a patient with data
      for prepopulation. As a part of this workflow, the DTR SMART App client must demonstrate its ability to:

      1. Request the Questionnaire using the $questionnaire-package operation,
      2. Support the tester in completing the questionnaire, including
        - Fetching additional data needed for pre-population
        - Rendering the questionnaire.
        - Pre-populating at least two answers into the questionnaire.
        - Allowing the tester to manually enter responses, including overriding pre-populated answers.
      3. Provide the completed QuestionnaireResponse with appropriate indicators for pre-populated
         and manually-entered data.
    )

    group do
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
      test from: :dtr_smart_app_questionnaire_package_request do
        input :custom_questionnaire_package_response
      end
      # Test 2: validate the $questionnaire-package body
      test from: :dtr_questionnaire_package_request_validation
      # Test 3: validate the user provided $questionnaire-package response
      test from: :dtr_custom_questionnaire_package_validation
      # Test 4: verify the custom response has the necessary libraries for pre-population
      test from: :dtr_custom_questionnaire_libraries
      # Test 5: verify the custom response has the necessaru extensions for pre-population
      test from: :dtr_custom_questionnaire_extensions
      # Test 6: verify custom response has necessary expressions for pre-population
      test from: :dtr_custom_questionnaire_expressions
    end

    group do
      id :dtr_smart_app_custom_static_rendering
      title 'Filling Out the Static Questionnaire'
      description %(
        The tester will interact with the questionnaire within their client system
        such that pre-population steps are taken, the qustionnaire is rendered, and
        they are able to fill it out. The tester will attest that questionnaire pre-population
        and rendering directives were followed.
      )
      run_as_group

      # Test 1: attest to proper rendering of the Questionnaire
      test from: :dtr_rendering_attestation
      # Test 1: attest to the pre-population
      test from: :dtr_prepopulation_attestation
      # Test 2: attest to the ability to manually complete questions
      test from: :dtr_prepopulation_override_attestation
    end

    group from: :dtr_smart_app_saving_questionnaire_response do
      config(options: { custom: true })
      test from: :dtr_smart_app_qr_correctness,
           uses_request: :questionnaire_response_save
    end
  end
end
