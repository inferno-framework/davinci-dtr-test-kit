require_relative '../dtr_full_ehr_abstract_adaptive_group'

module DaVinciDTRTestKit
  class DTRFullEHRV220AdditionalQuestionnairesForMS < DTRFullEHRV220AbstractAdaptive
    title 'Additional Questionnaires for Must Support Coverage'
    id :dtr_full_ehr_v220_additional_qustionnaires_for_ms
    description <<~DESCRIPTION
      During this group, the DTR client will have the opportunity to
      complete additional Questionnaires to demonstrate must support
      element coverage.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: false,
        dtr_workflow_tag: 'additional_must_support',
        qp_response_template_input: 'additional_ms_qp_responses',
        nq_questionnaire_template_input: 'additional_ms_nq_responses',
        short_circuit_pass_input: 'complete_additional_questionnaires',
        short_circuit_pass_message: 'Tester chose not to complete additional Questionnaires.',
        adaptive_questionnaires_optional: true
      }
    )

    input :complete_additional_questionnaires,
          title: 'Complete additional Questionnaires?',
          type: 'radio',
          options: {
            list_options: [
              {
                label: 'Yes, demonstrate more Questionnaires with additional must support elements now.',
                value: 'true'
              },
              {
                label: 'No, all must support elements were already demonstrated in previous tests.',
                value: 'false'
              }
            ]
          },
          optional: false,
          description: %(
            Must support evaluation will consider all Questionnaires completed during the most
            recent execution of each scenario during this session. Select `Yes` to provide
            additional Questionnaires for Inferno to respond with now so that the remaining must support
            elements can be demonstrated. Otherwise, select `No` to evaluate must support requirements
            without completing additional Questionnaires.
          ),
          default: 'true'
    input :additional_ms_qp_responses,
          title: 'Additional Must Support $questionnaire-package Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for $questionnaire-package responses for Inferno to send back.
          ),
          enable_when: { input_name: 'complete_additional_questionnaires', value: 'true' },
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'empty_templates',
                                       'parameters_questionnaire_package_empty.json'))
    input :additional_ms_nq_responses,
          title: 'Additional Must Support $next-question Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for $next-question responses for Inferno to send back. May be a single
            Questionnaire or a JSON array of Questionnaires; when an array is provided, Inferno
            selects the first Questionnaire whose url (and version, if the request's contained
            Questionnaire has one) matches the contained Questionnaire in the request.
          ),
          enable_when: { input_name: 'complete_additional_questionnaires', value: 'true' },
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'empty_templates',
                                       'next_question_template_empty.json'))
  end
end
