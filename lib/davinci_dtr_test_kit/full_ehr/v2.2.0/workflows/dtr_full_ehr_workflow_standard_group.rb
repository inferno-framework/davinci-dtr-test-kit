require_relative '../dtr_full_ehr_abstract_standard_group'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowStandard < DTRFullEHRV220AbstractStandard
    title 'Standard Questionnaire'
    id :dtr_full_ehr_v220_workflow_standard
    description <<~DESCRIPTION
      During this group, the DTR Full EHR will demonstrate its ability to complete
      a standard Questionnaire.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'static',
        qp_response_template_fixture: File.join('dinner_static', 'parameters_questionnaire_dinner_order_static.json')
      }
    )
  end
end
