require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireResponseCorrectnessTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_qr_correctness
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      Verify that the QuestionnaireResponse meets the expected workflow requirements by verifying the following:
      This includes:
        - **Completion Check**: Confirm that all required questions have been answered.
        - **Origin Source Validation**: Verify that specific answers are derived from the correct sources:
          - `PBD.1` (Last Name) and `LOC.1` (Location): `auto`
          - `PBD.2` (First Name): `override`
          - `3` (all nested dinner questions): `manual`
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@212'

    run do
      skip_if questionnaire_response.blank?, 'Completed QuestionnaireResponse input was blank'

      validate_questionnaire_response_correctness(questionnaire_response, try(:custom_questionnaire_package_response))
    end
  end
end
