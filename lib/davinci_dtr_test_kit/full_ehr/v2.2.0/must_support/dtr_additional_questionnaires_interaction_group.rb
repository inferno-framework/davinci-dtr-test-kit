require_relative '../dtr_full_ehr_abstract_adaptive_group'

module DaVinciDTRTestKit
  class DTRFullEHRV220AdditionalQuestionnairesForMS < DTRFullEHRV220AbstractAdaptive
    title 'Additional Questionnaires for Must Support Coverage'
    id :dtr_full_ehr_v220_additional_qustionnaires_for_ms
    description <<~DESCRIPTION
      During this group, the DTR client will have the opportunity to demonstrate
      the completion of additional Questionnaires to demonstrate must support
      element coverage.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: false,
        dtr_workflow_tag: 'additional_must_support',
        qp_response_template_input: 'additional_ms_qp_responses',
        nq_questionnaire_template_input: 'additional_ms_nq_responses'
      }
    )

    input :additional_ms_qp_responses,
          title: 'Additional Must Support $questionnaire-package Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for $questionnaire-package responses for Inferno to send back.
          ),
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'empty_templates',
                                       'parameters_questionnaire_package_empty.json'))
    input :additional_ms_nq_responses,
          title: 'Additional Must Support $next-question Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for $next-question responses for Inferno to send back.
          ),
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'empty_templates',
                                       'next_question_template_empty.json'))
  end
end
