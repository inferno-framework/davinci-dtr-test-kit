require_relative '../../urls'
require 'base64'

module DaVinciDTRTestKit
  class DTRSmartAppMSQuestionnairePackageRequestTest < Inferno::Test
    include URLs

    id :dtr_smart_app_ms_qp_request
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

    input :custom_questionnaire_package_response
    input :smart_app_launch,
          type: 'radio',
          title: 'SMART App Launch',
          description: 'How will the DTR SMART App launch?',
          options: { list_options: [{ label: 'EHR Launch from Inferno', value: 'ehr' },
                                    { label: 'Standalone Launch', value: 'standalone' }] }
    input :client_id
    input :launch_uri,
          optional: true,
          description: 'Required if "Launch from Inferno" is selected'
    input :static_smart_patient_id,
          optional: true,
          title: 'SMART App Launch Patient ID',
          type: 'text',
          description: %(
            Patient instance ID to be provided by Inferno as the patient as a part of the SMART App Launch.
          ),
          default: 'pat015'
    input :ms_static_smart_fhir_context,
          optional: true,
          title: 'SMART App Launch fhirContext for mustSupport Test',
          type: 'textarea',
          description: %(
            References to be provided by Inferno as the fhirContext as a part of the SMART App
            Launch. These references help determine the behavior of the app. Referenced instances
            may be provided in the "EHR-available resources" input.
          ),
          default: JSON.pretty_generate([{ reference: 'Coverage/cov015' },
                                         { reference: 'DeviceRequest/devreqe0470' }])
    input :ms_static_ehr_bundle,
          optional: true,
          title: 'EHR-available resources for mustSupport test',
          type: 'textarea',
          description: %(
            Resources available from the EHR needed to drive this workflow.
            Formatted as a FHIR bundle that contains resources, each with an ID property populated. Each
            instance present will be available for retrieval from Inferno at the endpoint:
            <fhir-base>/<resource type>/<instance id>
          )

    def example_client_jwt_payload_part
      Base64.strict_encode64({ inferno_client_id: client_id }.to_json).delete('=')
    end

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
      # validate relevant inputs and provide warnings if they are bad
      warning do
        if ms_static_smart_fhir_context
          assert_valid_json(ms_static_smart_fhir_context,
                            'The **SMART App Launch fhirContext** input is not valid JSON, so it will not be included in
                            the access token response.')
        end
      end

      launch_prompt = if smart_app_launch == 'ehr'
                        %(Launch the DTR SMART App from Inferno by right clicking
                        [this link](#{launch_uri}?iss=#{fhir_base_url}&launch=#{launch_uri})
                        and selecting "Open in new window" or "Open in new tab".)
                      else
                        %(Launch the SMART App from your EHR.)
                      end
      inferno_prompt_cont = %(As the DTR app steps through the launch steps, Inferno will wait and respond to the app's
                            requests for SMART configuration, authorization and access token.)

      wait(
        identifier: client_id,
        timeout: 1800,
        message: %(
          ### SMART APP Lauch and Questionnaire Package

          #{launch_prompt}

          #{inferno_prompt_cont if smart_app_launch == 'ehr'}

          Then, Inferno will wait for the SMART APP to invoke the DTR Questionnaire Package operation by sending a POST
          request to

          `#{questionnaire_package_url}`

          Inferno will return the **user-provided Questionnaire package** in the response.

          ###  Pre-population and MustSupport Elements Visual Inspection

          After the Questionnaire package is loaded, Inferno will wait for the client to
          complete Questionnaire pre-population. The client should make FHIR GET requests using service base path:

          `#{fhir_base_url}`

          The tester will complete the form(s) within the client system and
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
          Bearer eyJhbGciOiJub25lIn0.#{example_client_jwt_payload_part}.
          ```

          ### Continuing the Tests

          Once the Questionnaire has been loaded and the visual inspection is complete,
          [Click here](#{resume_pass_url}?client_id=#{client_id}) to continue.
        )
      )
    end
  end
end
