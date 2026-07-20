require_relative 'interaction/interaction_wait_test'
require_relative 'interaction/ui_display_and_interaction_attestation_test'
require_relative 'request/dtr_questionnaire_package_request_validation_test'
require_relative 'response/dtr_questionnaire_package_response_validation_test'
require_relative 'questionnaire_response/questionnaire_response_completion_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowStatic < Inferno::TestGroup
    title 'Static Questionnaire'
    id :dtr_full_ehr_v220_workflow_static
    description <<~DESCRIPTION
      During this group, the DTR Full EHR will demonstrate its ability to complete
      a static Questionnaire.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'static',
        qp_response_template_fixture: File.join('dinner_static', 'parameters_questionnaire_dinner_order_static.json')
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
      title 'QuestionnaireResponse Storage'
      test from: :dtr_full_ehr_v220_questionnaire_response_completion_attestation
    end
  end
end
