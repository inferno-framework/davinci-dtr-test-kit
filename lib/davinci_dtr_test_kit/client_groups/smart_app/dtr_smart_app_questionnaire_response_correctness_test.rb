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
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@209', 'hl7.fhir.us.davinci-dtr_2.0.1@210'

    input :custom_questionnaire_package_response,
          title: 'Custom Questionnaire Package Response JSON',
          description: %(
            The custom $questionnaire-package response used in the previous tests, if provided.
          ),
          type: 'textarea',
          optional: true,
          locked: true

    run do
      validate_questionnaire_response_correctness(request.request_body, custom_questionnaire_package_response)
    end
  end
end
