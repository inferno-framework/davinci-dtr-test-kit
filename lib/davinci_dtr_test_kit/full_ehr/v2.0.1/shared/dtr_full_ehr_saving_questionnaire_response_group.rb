require_relative 'dtr_full_ehr_store_attestation_test'
require_relative 'dtr_full_ehr_questionnaire_response_conformance_test'
require_relative 'dtr_full_ehr_questionnaire_response_correctness_test'

module DaVinciDTRTestKit
  class DTRFullEHRSavingQuestionnaireResponseGroup < Inferno::TestGroup
    id :dtr_full_ehr_saving_qr
    title 'Saving the QuestionnaireResponse'
    description %(
        The tester will attest to the completion of the questionnaire such that
        the results are stored for later use.
      )
    input :questionnaire_response,
          type: 'textarea',
          title: 'Completed QuestionnaireResponse',
          optional: true,
          description: %(
              The QuestionnaireResponse as exported from the EHR after completion of the Questionnaire.
            )
    run_as_group

    # Test 1: attest QuestionnaireResponse saved
    test from: :dtr_full_ehr_store_attest
    # Test 2: verify basic conformance of the QuestionnaireResponse
    test from: :dtr_full_ehr_qr_conformance
    # Test 3: check workflow-specific details such as pre-population and overrides
    test from: :dtr_full_ehr_qr_correctness
  end
end
