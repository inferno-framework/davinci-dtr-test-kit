require_relative 'dtr_full_ehr_custom_static_retrieval_group'
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

    group from: :dtr_full_ehr_custom_static_retrieval

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
      input :custom_questionnaire_package_response,
            title: 'Custom Questionnaire Package Response JSON',
            description: %(
              A JSON PackageBundle may be provided here to replace Inferno's response to the
              $questionnaire-package request.
            ),
            type: 'textarea'

      config(
        inputs: {
          questionnaire_response: {
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
