require_relative '../interaction/interaction_wait_test'
require_relative 'resume_answer_sequence_test'
require_relative 'resume_questionnaire_attestation_test'
require_relative '../request/dtr_questionnaire_package_request_validation_test'
require_relative 'dtr_questionnaire_package_changedsince_test'
require_relative '../response/dtr_questionnaire_package_response_validation_test'
require_relative '../request/dtr_next_question_request_validation_test'
require_relative '../response/dtr_next_question_response_validation_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowResume < Inferno::TestGroup
    title 'Resume a Questionnaire'
    id :dtr_full_ehr_v220_workflow_resume
    description <<~DESCRIPTION
      During this group, the DTR client will demonstrate its ability to save an in-progress
      QuestionnaireResponse and resume it later, using Inferno's Resume Questionnaire. It is an
      adaptive Questionnaire with three required questions, each returned by $next-question after
      the previous one is answered. The tester will
      1. Retrieve the Questionnaire, answer question 1 to get question 2, then save the
         in-progress QuestionnaireResponse without answering question 2, and close DTR.
      2. Relaunch DTR from the saved QuestionnaireResponse. When resuming, the client
         SHALL invoke the $questionnaire-package operation with the `changedsince` timestamp
         to see if the Questionnaire package has changed since it was last retrieved. Inferno's
         Questionnaire packages don't change, so Inferno will respond that nothing has changed.
      3. Answer question 2 to get question 3, answer question 3, and save the completed
         QuestionnaireResponse.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        qp_unchanged_since: true,
        dtr_workflow_tag: 'resume',
        qp_response_template_fixture: File.join('resume', 'parameters_questionnaire_resume_adaptive.json'),
        nq_questionnaire_template_fixture: File.join('resume', 'resume_adaptive_next_question_template.json')
      }
    )

    group do
      title 'Interaction'

      test from: :dtr_full_ehr_v220_interaction_wait,
           id: :dtr_full_ehr_v220_resume_initial_interaction_wait,
           title: 'Retrieve, partially complete, and save a Questionnaire',
           description: %(
             Inferno will act as a Payer DTR Server while the tester launches DTR, retrieves the Resume
             Questionnaire, answers question 1, and saves the in-progress QuestionnaireResponse.
           ),
           config: {
             options: {
               dtr_interaction_tag: DTRFullEHRV220ResumeAnswerSequenceTest::BEFORE_PAUSE_TAG,
               interaction_instructions: <<~INSTRUCTIONS
                 In this first step, do **not** complete the Questionnaire:
                 - Launch DTR and retrieve Inferno's Resume Questionnaire.
                 - Answer question 1. Inferno then returns question 2.
                 - Without answering question 2, save the in-progress QuestionnaireResponse and close DTR.

                 For this step, the saved in-progress QuestionnaireResponse counts as "completed and saved";
                 it will be resumed and completed in the next test.
               INSTRUCTIONS
             }
           }

      test from: :dtr_full_ehr_v220_interaction_wait,
           id: :dtr_full_ehr_v220_resume_relaunch_interaction_wait,
           title: 'Resume and complete the saved Questionnaire',
           description: %(
             Inferno will act as a Payer DTR Server while the tester relaunches DTR from the saved
             QuestionnaireResponse and completes it.
           ),
           config: {
             options: {
               dtr_interaction_tag: DTRFullEHRV220ResumeAnswerSequenceTest::AFTER_PAUSE_TAG,
               interaction_instructions: <<~INSTRUCTIONS
                 Relaunch DTR from the in-progress QuestionnaireResponse saved during the previous test.
                 The client should call $questionnaire-package with `changedsince`, and Inferno will
                 respond that nothing has changed. Then answer question 2 to get question 3, answer
                 question 3, and save the completed QuestionnaireResponse.
               INSTRUCTIONS
             }
           }

      test from: :dtr_full_ehr_v220_resume_answer_sequence
      test from: :dtr_full_ehr_v220_resume_questionnaire_attestation
    end

    group do
      title '$questionnaire-package'

      test from: :dtr_full_ehr_v220_qp_request_validation
      test from: :dtr_full_ehr_v220_qp_response_validation
      test from: :dtr_full_ehr_v220_qp_changedsince
    end

    group do
      title '$next-question'

      test from: :dtr_full_ehr_v220_nq_request_validation
      test from: :dtr_full_ehr_v220_nq_response_validation
    end
  end
end
