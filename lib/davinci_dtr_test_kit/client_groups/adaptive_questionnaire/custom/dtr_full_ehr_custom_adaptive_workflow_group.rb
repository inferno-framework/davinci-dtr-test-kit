require_relative '../../../tags'
require_relative 'dtr_full_ehr_custom_adaptive_retrieval_group'
require_relative '../../shared/dtr_prepopulation_attestation_test'
require_relative '../../shared/dtr_prepopulation_override_attestation_test'
require_relative '../../full_ehr/dtr_full_ehr_store_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRCustomAdaptiveWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_custom_adaptive_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This group validates that a DTR Full EHR client can perform a full DTR Adaptive Questionnaire workflow.
      Testers will provide a custom adaptive Questionnaire package for the test, along with a list
      (JSON array) of Questionnaires to be included in each `$next-question` response.

      As part of this workflow, the Full EHR system must demonstrate its ability to:

      1. Request the Questionnaire using the `$questionnaire-package` operation.
      2. Support the tester in completing the questionnaire through multiple `$next-question` interactions, including:
         - Rendering the questionnaire.
         - Pre-populating answers into the questionnaire.
         - Allowing the tester to manually enter responses, including overriding pre-populated answers.
      3. Complete and store the `QuestionnaireResponse` for future use.

      Inferno will process `$next-question` requests dynamically:
      - Each request will receive the next Questionnaire from the provided list.
      - If a `$next-question` request is received when the list is empty, Inferno will mark
        the `QuestionnaireResponse` as completed.

      At least two answers should be pre-populated across all sets of questions.
    )
    run_as_group
    config(
      options: { form_type: 'adaptive', next_tag: "custom_#{CLIENT_NEXT_TAG}" },
      inputs: {
        custom_questionnaire_package_response: {
          name: 'adaptive_custom_questionnaire_package_response',
          title: 'Custom Questionnaire Package Response JSON for Adaptive form',
          description: %(
              A JSON PackageBundle may be provided here to replace Inferno's response to
              the $questionnaire-package request. Note: Ensure that the questionnaire package
              has an empty Adaptive Questionnaire.
            )
        }
      }
    )

    input_order :access_token

    group from: :dtr_full_ehr_custom_adaptive_retrieval

    group do
      title 'Attestation: Questionnaire Pre-Population and Rendering'
      description %(
        This group verifies that the tester has properly followed pre-population and rendering
        directives while interacting with and filling out the questionnaire.

        After retrieving and completing the questionnaire in their client system, the tester will
        attest that:
        1. The questionnaire was pre-populated as expected, with at least two answers pre-populated
          across all sets of questions.
        2. The questionnaire was rendered correctly according to its defined structure.
        3. They were able to manually enter responses, including overriding pre-populated answers.
      )
      test from: :dtr_prepopulation_attest
      test from: :dtr_prepopulation_override_attest
    end

    group do
      title 'Attestation: QuestionnaireResponse Completion and Storage'
      description %(
        The tester will attest to the completion of the questionnaire such that the results are stored for later use.
      )

      test from: :dtr_full_ehr_store_attest
    end
  end
end
