require_relative '../dtr_full_ehr_abstract_adaptive_group'
require_relative '../interaction/answer_origin_verification_test'
require_relative '../interaction/prepopulation_review_not_required_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRV220WorkflowAnswerOrigin < DTRFullEHRV220AbstractAdaptive
    title 'Pre-populated Answers and Answer Origin'
    id :dtr_full_ehr_v220_workflow_answer_origin
    description <<~DESCRIPTION
      During this group, the DTR client will complete a short adaptive Questionnaire and demonstrate that
      - users can change pre-populated answers, but are not required to review or change them, and
      - the client records where each answer came from using the
        [information-origin](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-information-origin.html)
        extension.

      Inferno returns a Questionnaire with three questions, each labeled with what the tester should do:
      - **Last Name (don't change!)**: pre-populated with the patient's last name. Leave it as it is.
      - **Preferred First Name (update)**: pre-populated with the patient's first name. Change it.
      - **New Information (add details)**: not pre-populated. Fill it in.

      The two pre-populated questions use FHIRPath, so no CQL Libraries are needed. Complete the
      Questionnaire for a Patient that has a recorded first and last name.
    DESCRIPTION
    run_as_group

    config(
      options: {
        qp_single_use: true,
        dtr_workflow_tag: 'answer_origin',
        qp_response_template_fixture: File.join('answer_origin', 'answer_origin_questionnaire_package_response.json'),
        nq_questionnaire_template_fixture: File.join('answer_origin',
                                                     'answer_origin_adaptive_next_question_template.json'),
        interaction_instructions: <<~INSTRUCTIONS
          Launch DTR for a Patient that has a recorded first and last name, and complete the
          Questionnaire as its questions describe:
          - **Last Name (don't change!)**: leave the pre-populated last name as it is.
          - **Preferred First Name (update)**: change the pre-populated first name to something else.
          - **New Information (add details)**: type in any details.
        INSTRUCTIONS
      }
    )

    group do
      id :dtr_full_ehr_v220_answer_origin
      title 'Answer Origin'

      test from: :dtr_full_ehr_v220_answer_origin_verification
      test from: :dtr_full_ehr_v220_prepopulation_review_not_required_attestation
    end
  end
end
