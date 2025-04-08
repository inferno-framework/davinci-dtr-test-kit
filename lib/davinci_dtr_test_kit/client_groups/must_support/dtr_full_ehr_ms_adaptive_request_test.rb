require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRMSAdaptiveRequestTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_ms_adative_request
    title 'Complete the DTR Adaptive Questionnaire workflow and Demonstrate mustSupport Handling'
    description %(
      This test waits for client requests to retrieve and progress through an adaptive questionnaire workflow.

      1. **Questionnaire Package Request**: The client should invoke the `$questionnaire-package` operation
         to retrieve the adaptive questionnaire package. Inferno will respond with the user-provided
         empty adaptive questionnaire.

      2. **Next Question Requests**: The client should invoke the `$next-question` operation to request
         the next set of questions. Inferno will respond sequentially with the next Questionnaire from
         the user-provided list. If a `$next-question` request is received when the list is empty,
         Inferno will mark the `QuestionnaireResponse` as completed.

      3. **mustSupport Visual Inspection**: The tester will demonstrate that the client system supports the
          following `mustSupport` elements as  defined in the [DTR Questionnaire for adaptive form](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt)
          profile:

          - Questionnaire.version
          - Questionnaire.title
          - Questionnaire.derivedFrom
          - Questionnaire.status
          - Questionnaire.effectivePeriod
          - Questionnaire.item
          - Questionnaire.item.linkId
          - Questionnaire.item.prefix
          - Questionnaire.item.text
          - Questionnaire.item.type
          - Questionnaire.item.required
          - Questionnaire.item.repeats
          - Questionnaire.item.readOnly
          - Questionnaire.item.answerOption
          - Questionnaire.item.answerOption.value[x]
          - Questionnaire.item.initial
          - Questionnaire.item.initial.value[x]
          - Questionnaire.item.item
          - Questionnaire.extension:questionnaireAdaptive
          - Questionnaire.extension:cqf-library
          - Questionnaire.extension:itemPopulationContext
          - Questionnaire.item.extension:hidden
          - Questionnaire.item.extension:itemControl
          - Questionnaire.item.extension:supportLink
          - Questionnaire.item.extension:initialExpression
          - Questionnaire.item.extension:candidateExpression
          - Questionnaire.item.extension:contextExpression
          - Questionnaire.item.text.extension:itemTextRenderingXhtml
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@165', 'hl7.fhir.us.davinci-dtr_2.0.1@262',
                          'hl7.fhir.us.davinci-dtr_2.0.1@264'

    config options: { accepts_multiple_requests: true }
    input :access_token,
          description: %(
            `Bearer` token that the client under test will send in the
            `Authorization` header of each HTTP request to Inferno. Inferno
            will look for this value to associate requests with this session.
          )
    input :custom_questionnaire_package_response, :custom_next_question_questionnaires

    run do
      assert_valid_json(
        custom_questionnaire_package_response,
        'Custom questionnaire package response is not a valid json'
      )
      assert_valid_json(custom_next_question_questionnaires, 'Custom next questionnaires input is not a valid json')

      custom_qp = JSON.parse(custom_questionnaire_package_response)
      custom_questionnaires = JSON.parse(custom_next_question_questionnaires)
      assert custom_qp.present?, %(
        Custom questionnaire package response is empty, please provide a custom questionnaire package response
        for the $questionnaire-package request
      )
      assert custom_questionnaires.present?, %(
        'Custom questionnaires list is empty, please provide a list of Custom Questionnaire resources
        to include in each $next-question Response.
      )
      wait(
        identifier: access_token,
        timeout: 1800,
        message: %(
          ### Adaptive Questionnaire Workflow

          1. **Questionnaire Package Request**:
             - Invoke the `$questionnaire-package` operation by sending a POST request to the following endpoint
               to retrieve the adaptive questionnaire package:

               `#{questionnaire_package_url}`

             - Inferno will respond with the user-provided empty adaptive questionnaire.

          2. **Next Question Requests**:
             - After receiving the questionnaire package, invoke the `$next-question` operation by sending
               a POST request to the following endpoint:

               `#{next_url}`

             - Repeat this request **multiple times**, once for each Questionnaire provided in the user-supplied list.
             - Inferno will sequentially respond with the corresponding Questionnaire from the list.
             - If a `$next-question` request is received when the list is empty, Inferno will mark
               the `QuestionnaireResponse` as completed.

          3. **MustSupport Elements Visual Inspection**:

              After each `$next-question` request, complete the form within the client system and
              **visually inspect** that the application correctly supports all `mustSupport` elements as defined in the
              [DTR Questionnaire for adaptive form](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt)
              profile. Support should be demonstrated via visual cues, UI behavior, or other relevant indicators.

              The `mustSupport` elements include:

              `Questionnaire.version`, `Questionnaire.title`, `Questionnaire.derivedFrom`, `Questionnaire.status`,
              `Questionnaire.effectivePeriod`, `Questionnaire.item`, `Questionnaire.item.linkId`,
              `Questionnaire.item.prefix`, `Questionnaire.item.text`, `Questionnaire.item.type`,
              `Questionnaire.item.required`, `Questionnaire.item.repeats`, `Questionnaire.item.readOnly`,
              `Questionnaire.item.answerOption`, `Questionnaire.item.answerOption.value[x]`,
              `Questionnaire.item.initial`, `Questionnaire.item.initial.value[x]`, `Questionnaire.item.item`,
              `Questionnaire.extension:questionnaireAdaptive`, `Questionnaire.extension:cqf-library`,
              `Questionnaire.extension:itemPopulationContext`, `Questionnaire.item.extension:hidden`,
              `Questionnaire.item.extension:itemControl`, `Questionnaire.item.extension:supportLink`,
              `Questionnaire.item.extension:initialExpression`, `Questionnaire.item.extension:candidateExpression`,
              `Questionnaire.item.extension:contextExpression`,
              `Questionnaire.item.text.extension:itemTextRenderingXhtml`


          ### Request Identification

          To identify requests for this session, Inferno will look for an `Authorization` header with the value:

          ```
          Bearer #{access_token}
          ```

          ### Continuing the Tests

          Once all required `$next-question` requests have been made and the visual inspection is complete,
          [Click here](#{resume_pass_url}?token=#{access_token}) to continue.
        )
      )
    end
  end
end
