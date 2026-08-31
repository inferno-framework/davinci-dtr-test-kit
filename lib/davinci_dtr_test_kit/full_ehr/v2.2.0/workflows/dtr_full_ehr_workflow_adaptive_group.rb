require_relative '../dtr_full_ehr_abstract_adaptive_group'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowAdaptive < DTRFullEHRV220AbstractAdaptive
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
  end
end
