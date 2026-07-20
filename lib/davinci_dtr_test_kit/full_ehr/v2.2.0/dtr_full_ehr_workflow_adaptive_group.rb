require_relative 'interaction/interaction_wait_test'
require_relative 'interaction/ui_display_and_interaction_attestation_test'
require_relative 'request/dtr_questionnaire_package_request_validation_test'
require_relative 'response/dtr_questionnaire_package_response_validation_test'
require_relative 'request/dtr_next_question_request_validation_test'
require_relative 'response/dtr_next_question_response_validation_test'
require_relative 'questionnaire_response/questionnaire_response_completion_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowAdaptive < Inferno::TestGroup
    title 'Adaptive Questionnaire'
    id :dtr_full_ehr_v220_workflow_adaptive
    description <<~DESCRIPTION
      During this group, the DTR Full EHR will demonstrate its ability to complete
      an adaptive Questionnaire.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'adaptive',
        qp_response_template_fixture: File.join('dinner_adaptive',
                                                'parameters_questionnaire_dinner_order_adaptive.json'),
        nq_questionnaire_template_fixture: File.join('dinner_adaptive',
                                                     'dinner_order_adaptive_next_question_template.json')
      }
    )

    group do
      title 'Interaction'
      test from: :dtr_full_ehr_v220_interaction_wait
      test from: :dtr_full_ehr_v220_ui_display_and_interaction
    end

    group do
      title '$questionnaire-package'
      test from: :dtr_full_ehr_v220_qp_request_validation
      test from: :dtr_full_ehr_v220_qp_response_validation
    end

    group do
      title '$next-question'
      test from: :dtr_full_ehr_v220_nq_request_validation
      test from: :dtr_full_ehr_v220_nq_response_validation
    end

    group do
      title 'QuestionnaireResponse Storage'
      test from: :dtr_full_ehr_v220_questionnaire_response_completion_attestation
    end
  end
end
