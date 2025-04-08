require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRSmartAppMSAdaptiveRequestTest < Inferno::Test
    include URLs

    id :dtr_smart_app_ms_adative_request
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

    config options: { accepts_multiple_requests: true }
    input :custom_questionnaire_package_response, :custom_next_question_questionnaires
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
          ### SMART App Launch

          #{launch_prompt}

          #{inferno_prompt_cont if smart_app_launch == 'ehr'}

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

          3. **Pre-population and MustSupport Elements Visual Inspection**:

              Inferno will then wait for the client to complete Questionnaire pre-population.
              The client should make FHIR GET requests using service base path:

              `#{fhir_base_url}`

              After each `$next-question` request, the tester will complete the form within the client system and
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
          Bearer eyJhbGciOiJub25lIn0.#{example_client_jwt_payload_part}.
          ```

          ### Continuing the Tests

          Once all required `$next-question` requests have been made and the visual inspection is complete,
          [Click here](#{resume_pass_url}?client_id=#{client_id}) to continue.
        )
      )
    end
  end
end
