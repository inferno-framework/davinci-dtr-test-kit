require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRFullEHRMSQuestionnairePackageRequestTest < Inferno::Test
    include URLs

    id :dtr_full_ehr_ms_qp_request
    title 'Invoke the Questionnaire Package Operation and Demonstrate mustSupport Handling'
    description %(
      Inferno will wait for a DTR Questionnaire package request from the client. Upon receipt,
      Inferno will return the user-provided Questionnaire package as the response to the $questionnaire-package request.

      Afterward, Inferno will wait for the user to visually demonstrate support (via UI cues or guidance)
      for the following mustSupport elements, as defined in the [DTR Standard Questionnaire profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire):

        - Questionnaire.url
        - Questionnaire.version
        - Questionnaire.title
        - Questionnaire.status
        - Questionnaire.subjectType
        - Questionnaire.effectivePeriod
        - Questionnaire.item
        - Questionnaire.item.linkId
        - Questionnaire.item.prefix
        - Questionnaire.item.text
        - Questionnaire.item.type
        - Questionnaire.item.enableWhen
        - Questionnaire.item.enableBehavior
        - Questionnaire.item.required
        - Questionnaire.item.repeats
        - Questionnaire.item.readOnly
        - Questionnaire.item.maxLength
        - Questionnaire.item.answerValueSet
        - Questionnaire.item.answerOption
        - Questionnaire.item.answerOption.value[x]
        - Questionnaire.item.initial
        - Questionnaire.item.initial.value[x]
        - Questionnaire.item.item
        - Questionnaire.extension:terminologyServer
        - Questionnaire.extension:performerType
        - Questionnaire.extension:assemble-expectation
        - Questionnaire.extension:entryMode
        - Questionnaire.extension:signatureRequired
        - Questionnaire.extension:cqf-library
        - Questionnaire.extension:launchContext
        - Questionnaire.extension:variable
        - Questionnaire.extension:itemPopulationContext
        - Questionnaire.item.extension:itemHidden
        - Questionnaire.item.extension:itemControl
        - Questionnaire.item.extension:supportLink
        - Questionnaire.item.extension:mimeType
        - Questionnaire.item.extension:unitOption
        - Questionnaire.item.extension:unitValueSet
        - Questionnaire.item.extension:referenceResource
        - Questionnaire.item.extension:referenceProfile
        - Questionnaire.item.extension:candidateExpression
        - Questionnaire.item.extension:lookupQuestionnaire
        - Questionnaire.item.extension:initialExpression
        - Questionnaire.item.extension:calculatedExpression
        - Questionnaire.item.extension:enableWhenExpression
        - Questionnaire.item.extension:contextExpression
        - Questionnaire.item.text.extension:itemTextRenderingXhtml
        - Questionnaire.item.answerOption.extension:optionExclusive
        - Questionnaire.item.answerOption.value[x].extension:answerOptionRenderingXhtml
    )
    config options: { accepts_multiple_requests: true }
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@165', 'hl7.fhir.us.davinci-dtr_2.0.1@262'
    input :access_token,
          description: %(
            `Bearer` token that the client under test will send in the
            `Authorization` header of each HTTP request to Inferno. Inferno
            will look for this value to associate requests with this session.
          )
    input :custom_questionnaire_package_response

    run do
      assert_valid_json(
        custom_questionnaire_package_response,
        'Custom questionnaire package response is not a valid json'
      )

      custom_qp = JSON.parse(custom_questionnaire_package_response)
      assert custom_qp.present?, %(
        Custom questionnaire package response is empty, please provide a custom questionnaire package response
        for the $questionnaire-package request
      )

      wait(
        identifier: access_token,
        timeout: 1800,
        message: %(
          ### Questionnaire Package

          Inferno will wait for the Full EHR to invoke the DTR Questionnaire Package operation by sending a POST
          request to

          `#{questionnaire_package_url}`

          Inferno will return the **user-provided Questionnaire package** in the response.

          ### MustSupport Elements Visual Inspection

          After the Questionnaire package is loaded, complete the form(s) within the client system and
          **visually inspect** that the application correctly supports all mustSupport elements as defined in the
          [DTR Standard Questionnaire profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire).
          Support should be demonstrated via visual cues, UI behavior, or other relevant indicators.

          The mustSupport elements include:

          `Questionnaire.url`, `Questionnaire.version`, `Questionnaire.title`, `Questionnaire.status`,
          `Questionnaire.subjectType`, `Questionnaire.effectivePeriod`, `Questionnaire.item`,
          `Questionnaire.item.linkId`, `Questionnaire.item.prefix`, `Questionnaire.item.text`,
          `Questionnaire.item.type`, `Questionnaire.item.enableWhen`, `Questionnaire.item.enableBehavior`,
          `Questionnaire.item.required`, `Questionnaire.item.repeats`, `Questionnaire.item.readOnly`,
          `Questionnaire.item.maxLength`, `Questionnaire.item.answerValueSet`, `Questionnaire.item.answerOption`,
          `Questionnaire.item.answerOption.value[x]`, `Questionnaire.item.initial`,
          `Questionnaire.item.initial.value[x]`, `Questionnaire.item.item`, `Questionnaire.extension:terminologyServer`,
          `Questionnaire.extension:performerType`, `Questionnaire.extension:assemble-expectation`,
          `Questionnaire.extension:entryMode`, `Questionnaire.extension:signatureRequired`,
          `Questionnaire.extension:cqf-library`, `Questionnaire.extension:launchContext`,
          `Questionnaire.extension:variable`, `Questionnaire.extension:itemPopulationContext`,
          `Questionnaire.item.extension:itemHidden`, `Questionnaire.item.extension:itemControl`,
          `Questionnaire.item.extension:supportLink`, `Questionnaire.item.extension:mimeType`,
          `Questionnaire.item.extension:unitOption`, `Questionnaire.item.extension:unitValueSet`,
          `Questionnaire.item.extension:referenceResource`, `Questionnaire.item.extension:referenceProfile`,
          `Questionnaire.item.extension:candidateExpression`, `Questionnaire.item.extension:lookupQuestionnaire`,
          `Questionnaire.item.extension:initialExpression`, `Questionnaire.item.extension:calculatedExpression`,
          `Questionnaire.item.extension:enableWhenExpression`, `Questionnaire.item.extension:contextExpression`,
          `Questionnaire.item.text.extension:itemTextRenderingXhtml`,
          `Questionnaire.item.answerOption.extension:optionExclusive`,
          `Questionnaire.item.answerOption.value[x].extension:answerOptionRenderingXhtml`


          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          Bearer #{access_token}
          ```

          ### Continuing the Tests

          Once the Questionnaire has been loaded and the visual inspection is complete,
          [Click here](#{resume_pass_url}?token=#{access_token}) to continue.
        )
      )
    end
  end
end
