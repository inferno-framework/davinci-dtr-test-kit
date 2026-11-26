require_relative '../../../tags'
require_relative '../dtr_full_ehr_abstract_adaptive_group'
require_relative 'resume_answer_sequence_test'
require_relative 'dtr_questionnaire_package_changedsince_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowResume < DTRFullEHRV220AbstractAdaptive
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
        dtr_workflow_tag: 'resume',
        qp_response_template_fixture: File.join('resume', 'parameters_questionnaire_resume_adaptive.json'),
        nq_questionnaire_template_fixture: File.join('resume', 'resume_adaptive_next_question_template.json')
      }
    )

    interaction_group, = groups

    interaction_group.replace :dtr_full_ehr_v220_interaction_wait, :dtr_full_ehr_v220_interaction_wait do
      id :dtr_full_ehr_v220_resume_initial_interaction_wait
      title 'Retrieve, partially complete, and save a Questionnaire'
      description %(
        Inferno will act as a Payer DTR Server while the tester launches DTR, retrieves the Resume
        Questionnaire, answers question 1, and saves the in-progress QuestionnaireResponse.
      )
      config(
        options: {
          dtr_sub_workflow_tag: RESUME_BEFORE_PAUSE_TAG,
          interaction_attestation: {
            instructions: <<~INSTRUCTIONS,
              Inferno will wait while the tester uses the DTR client to start Inferno's Resume Questionnaire,
              retrieved from Inferno's simulated payer server. In this first step, do **not** complete
              the Questionnaire:
              - Launch DTR.
              - Answer question 1 and continue the form to get the second question.
              - Without answering question 2, save the draft response and close the DTR session.
            INSTRUCTIONS
            statement: 'question 1 was answered and the in-progress response was saved without an ' \
                       'answer to question 2, and the DTR session was closed.'
          }
        }
      )
    end

    interaction_group.test from: :dtr_full_ehr_v220_interaction_wait do
      id :dtr_full_ehr_v220_resume_relaunch_interaction_wait
      title 'Resume and complete the saved Questionnaire'
      description %(
        Inferno will act as a Payer DTR Server while the tester relaunches DTR from the saved
        QuestionnaireResponse and completes it. If the tester attested that the previous step was
        not completed, there is nothing to resume, so this test is skipped.
      )
      config(
        options: {
          dtr_sub_workflow_tag: RESUME_AFTER_PAUSE_TAG,
          skip_if_attested_false: :dtr_full_ehr_v220_resume_initial_interaction_wait,
          interaction_attestation: {
            instructions: <<~INSTRUCTIONS,
              Inferno will wait while the tester uses the DTR client to resume and complete the
              in-progress Questionnaire saved during the previous test:
              - Relaunch DTR from the in-progress Questionnaire saved during the previous
                test.
              - Answer question 2 and continue the form to get question 3.
              - Answer question 3 and continue the form to complete it.
              - Save the completed form.
            INSTRUCTIONS
            statement: 'DTR relaunched with the answer to question 1 restored, and the Questionnaire ' \
                       'was completed and saved to the EHR.'
          }
        }
      )
    end

    # The relaunch wait goes right after the first wait, so the verification tests follow both.
    interaction_group.reorder :dtr_full_ehr_v220_resume_relaunch_interaction_wait, 1

    group do
      id :dtr_full_ehr_v220_resume
      title 'Resume'

      test from: :dtr_full_ehr_v220_resume_answer_sequence
      test from: :dtr_full_ehr_v220_qp_changedsince
    end
  end
end
