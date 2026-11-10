require_relative '../interaction/interaction_wait_test'
require_relative '../interaction/resume_questionnaire_attestation_test'
require_relative '../request/dtr_questionnaire_package_request_validation_test'
require_relative '../request/dtr_questionnaire_package_changedsince_test'
require_relative '../response/dtr_questionnaire_package_response_validation_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowResume < Inferno::TestGroup
    title 'Resume a Questionnaire'
    id :dtr_full_ehr_v220_workflow_resume
    description <<~DESCRIPTION
      During this group, the DTR client will demonstrate its ability to save an in-progress
      QuestionnaireResponse and resume it later. The tester will
      1. Retrieve a Questionnaire from Inferno, answer some of its questions, save the
         in-progress QuestionnaireResponse, and close DTR.
      2. Relaunch DTR from the saved QuestionnaireResponse. When resuming, the client
         SHALL invoke the $questionnaire-package operation with the `changedsince` timestamp
         to see if the Questionnaire package has changed since it was last retrieved. Inferno's
         Questionnaire packages don't change, so Inferno will respond that nothing has changed.
      3. Complete and save the resumed QuestionnaireResponse.

      Inferno returns the Questionnaire package in the
      "Resume a Questionnaire $questionnaire-package Response Template" input. By default, this is
      Inferno's Dinner Order (Static) Questionnaire, but testers may provide their own standard
      (non-adaptive) Questionnaire.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        qp_unchanged_since: true,
        dtr_workflow_tag: 'resume',
        qp_response_template_input: 'resume_qp_response_template'
      }
    )

    input :resume_qp_response_template,
          title: 'Resume a Questionnaire $questionnaire-package Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for the $questionnaire-package response that Inferno will send back when the
            Questionnaire is first retrieved. Must contain a standard (non-adaptive) Questionnaire.
            Defaults to Inferno's Dinner Order (Static) Questionnaire.
          ),
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'dinner_static',
                                       'parameters_questionnaire_dinner_order_static.json'))

    group do
      title 'Interaction'

      test from: :dtr_full_ehr_v220_interaction_wait,
           id: :dtr_full_ehr_v220_resume_initial_interaction_wait,
           title: 'Retrieve, partially complete, and save a Questionnaire',
           config: {
             options: {
               interaction_instructions: <<~INSTRUCTIONS
                 In this first step, do **not** complete the Questionnaire:
                 - Answer some, but not all, of its questions.
                 - Save the in-progress QuestionnaireResponse and close DTR.

                 For this step, the saved in-progress QuestionnaireResponse counts as "completed and saved";
                 it will be resumed and completed in the next test.
               INSTRUCTIONS
             }
           }

      test from: :dtr_full_ehr_v220_interaction_wait,
           id: :dtr_full_ehr_v220_resume_relaunch_interaction_wait,
           title: 'Resume and complete the saved Questionnaire',
           config: {
             options: {
               interaction_instructions: <<~INSTRUCTIONS
                 Relaunch DTR from the in-progress QuestionnaireResponse saved during the previous test.
                 The client should call $questionnaire-package with `changedsince`, and Inferno will
                 respond that nothing has changed. Then complete the resumed QuestionnaireResponse and save it.
               INSTRUCTIONS
             }
           }

      test from: :dtr_full_ehr_v220_resume_questionnaire_attestation
    end

    group do
      title '$questionnaire-package'

      test from: :dtr_full_ehr_v220_qp_request_validation
      test from: :dtr_full_ehr_v220_qp_response_validation
      test from: :dtr_full_ehr_v220_qp_changedsince
    end
  end
end
