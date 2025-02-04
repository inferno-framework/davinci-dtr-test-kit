require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRSmartAppQuestionnaireResponseCorrectnessTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_smart_app_qr_correctness
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      Verify that the QuestionnaireResponse
        - Is for the Questionnaire provided by the tester.
        - Has source extensions demonstrating answers that are manually entered,
          automatically pre-populated, and manually overridden.
        - Contains answers for all required items.
    )
    input :custom_questionnaire_package_response,
          title: 'Custom Questionnaire Package Response JSON',
          description: %(
            A JSON PackageBundle may be provided here to replace Inferno's response to the
            $questionnaire-package request.
          ),
          type: 'textarea'

    run do
      validate_questionnaire_response_correctness(request.request_body, custom_questionnaire_package_response)
    end
  end
end
