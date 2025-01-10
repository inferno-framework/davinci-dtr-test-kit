require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireResponseCorrectnessTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_questionnaire_response_correctness
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      This test verifies that all the QuestionnaireResponse.item have the appropriate
      origin source extensions and that all required questions have been answered.
    )
    input :custom_questionnaire_package_response,
          title: 'Custom Questionnaire Package Response JSON',
          description: %(
            A JSON PackageBundle may be provided here to replace Inferno's response to the
            $questionnaire-package request.
          ),
          type: 'textarea',
          optional: true

    run do
      skip_if questionnaire_response.blank?, 'Completed QuestionnaireResponse input was blank'

      validate_questionnaire_response_correctness(questionnaire_response, custom_questionnaire_package_response)
    end
  end
end
