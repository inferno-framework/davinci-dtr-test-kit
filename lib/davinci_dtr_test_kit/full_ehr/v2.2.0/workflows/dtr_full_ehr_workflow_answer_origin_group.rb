require_relative '../dtr_full_ehr_abstract_adaptive_group'
require_relative '../interaction/answer_origin_verification_test'
require_relative '../interaction/prepopulation_review_not_required_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowAnswerOrigin < DTRFullEHRV220AbstractAdaptive
    title 'Pre-populated Answers and Answer Origin'
    id :dtr_full_ehr_v220_workflow_answer_origin
    description <<~DESCRIPTION
      During this group, the DTR client will complete an adaptive Questionnaire and demonstrate that
      - users can change pre-populated answers, but are not required to review or change them, and
      - the client records where each answer came from using the
        [information-origin](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-information-origin.html)
        extension.

      By default, Inferno will return its default sample Questionnaire, which pre-populates the
      patient's name and location. Testers may instead provide their own Questionnaire through the inputs.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'answer_origin',
        qp_response_template_input: 'answer_origin_qp_template',
        nq_questionnaire_template_input: 'answer_origin_nq_template',
        nq_template_requires_answer_origin_items: true,
        interaction_instructions: <<~INSTRUCTIONS
          While completing the Questionnaire:
          - **Change** at least one pre-populated answer to a different value
            (with Inferno's default sample Questionnaire, change the patient's First Name).
          - **Leave** at least one pre-populated answer as it was
            (with Inferno's default sample Questionnaire, leave the patient's Last Name and Location alone).
          - **Fill in** at least one answer that was not pre-populated
            (with Inferno's default sample Questionnaire, answer the first question after the patient details).
        INSTRUCTIONS
      }
    )

    input :answer_origin_qp_template,
          title: 'Answer Origin $questionnaire-package Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for $questionnaire-package responses for Inferno to send back. The default returns
            Inferno's default sample adaptive Questionnaire. Replace it to use a different adaptive Questionnaire.
          ),
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'dinner_adaptive',
                                       'parameters_questionnaire_dinner_order_adaptive.json'))
    input :answer_origin_nq_template,
          title: 'Answer Origin $next-question Response Template',
          type: 'textarea',
          optional: false,
          description: %(
            Template for $next-question responses for Inferno to send back. May be a single Questionnaire or
            a JSON array of Questionnaires. It must include at least two pre-populated items (using an
            `initialExpression` or `candidateExpression`) and at least one item that is not pre-populated,
            all of which users can edit.
          ),
          default: File.read(File.join(__dir__, '..', '..', 'fixtures', 'dinner_adaptive',
                                       'dinner_order_adaptive_next_question_template.json'))

    group do
      id :dtr_full_ehr_v220_answer_origin
      title 'Answer Origin'

      test from: :dtr_full_ehr_v220_answer_origin_verification
      test from: :dtr_full_ehr_v220_prepopulation_review_not_required_attestation
    end
  end
end
