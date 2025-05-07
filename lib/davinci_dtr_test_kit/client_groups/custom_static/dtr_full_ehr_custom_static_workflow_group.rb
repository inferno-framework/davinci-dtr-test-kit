require_relative '../shared/dtr_custom_questionnaire_package_validation_test'
require_relative '../shared/dtr_custom_questionnaire_libraries_test'
require_relative '../shared/dtr_custom_questionnaire_extensions_test'
require_relative '../shared/dtr_custom_questionnaire_expressions_test'
require_relative '../full_ehr/dtr_full_ehr_launch_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'
require_relative '../shared/dtr_prepopulation_attestation_test'
require_relative '../shared/dtr_rendering_attestation_test'
require_relative '../shared/dtr_prepopulation_override_attestation_test'
require_relative '../full_ehr/dtr_full_ehr_saving_questionnaire_response_group'

module DaVinciDTRTestKit
  class DTRFullEHRCustomStaticWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_custom_static_workflow
    title 'Static Questionnaire Workflow'
    description %(
      This group validates that a DTR Full EHR client can perform a full DTR Static Questionnaire workflow.
      Testers will provide a custom Questionnaire package of their choice for the test and
      will request and complete the Questionnaire in the context of a patient with data
      for prepopulation. As a part of this workflow, the Full EHR system must demonstrate its ability to:

      1. Request the Questionnaire using the $questionnaire-package operation,
      2. Support the tester in completing the questionnaire, including
         - Rendering the questionnaire.
         - Pre-populating at least two answers into the questionnaire.
         - Allowing the tester to manually enter responses, including overriding pre-populated answers.
      3. Complete and store the QuestionnaireResponse for future use.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@35', 'hl7.fhir.us.davinci-dtr_2.0.1@208'

    input_order :custom_questionnaire_package_response, :static_custom_questionnaire_response

    group do
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

      input_order :custom_questionnaire_package_response

      # Test 0: attest to launch
      test from: :dtr_full_ehr_launch_attest,
           config: { options: { attestation_message:
              'I attest that DTR has been launched in the context of a patient with data that will exercise pre-population logic in the provided static questionnaire resulting in at least 2 pre-populated answers.' } }, # rubocop:disable Layout/LineLength
           title: 'Launch DTR (Attestation)'
      # Test 1: wait for the $questionnaire-package request
      test from: :dtr_full_ehr_qp_request do
        input :custom_questionnaire_package_response,
              title: 'Custom Questionnaire Package Response JSON',
              description: %(
                Provide a JSON FHIR Bundle containing a custom questionnaire for Inferno to use as a response to
                the $questionnaire-package request.
              ),
              optional: false
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

    group do
      id :dtr_full_ehr_custom_static_rendering
      title 'Filling Out the Static Questionnaire'
      description %(
        The tester will interact with the questionnaire within their client system
        such that pre-population steps are taken, the questionnaire is rendered, and
        they are able to fill it out. The tester will attest that questionnaire pre-population
        and rendering directives were followed.
      )
      run_as_group

      # Test 1: attest to proper rendering of the Questionnaire
      test from: :dtr_rendering_attest
      # Test 2: attest to the pre-population
      test from: :dtr_prepopulation_attest
      # Test 2: attest to the ability to manually complete questions
      test from: :dtr_prepopulation_override_attest
    end

    group from: :dtr_full_ehr_saving_qr do
      config(
        inputs: {
          questionnaire_response: {
            name: 'static_custom_questionnaire_response',
            description: "The QuestionnaireResponse as exported from the EHR after completion of the Questionnaire.
                IMPORTANT: If you have not yet run the 'Filling Out the Static Questionnaire' group, leave this blank
                until you have done so. Then, run just the 'Saving the QuestionnaireResponse' group and populate
                this input."
          }
        }
      )

      children.last.description(
        %(
           Verify that the QuestionnaireResponse
            - Is for the Questionnaire provided by the tester.
            - Has source extensions demonstrating answers that are manually entered,
             automatically pre-populated, and manually overridden.
            - Contains answers for all required items.
         )
      )
    end
  end
end
