require_relative '../../../urls'

module DaVinciDTRTestKit
  class DTRSmartAppAdaptiveRequestTest < Inferno::Test
    include URLs

    id :dtr_smart_app_adaptive_request
    title 'Invoke the Questionnaire Package and Initial Next Question Operation'
    description %(
      This test waits for two sequential client requests:

      1. **Questionnaire Package Request**: The client should first invoke the `$questionnaire-package` operation
      to retrieve the adaptive questionnaire package. Inferno will respond to this request with an empty adaptive
      questionnaire.

      2. **Initial Next Question Request**: After receiving the package, the client should invoke the
      `$next-question` operation. Inferno will respond by providing the first set of questions.
    )

    config options: { accepts_multiple_requests: true }
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
    input :adaptive_smart_patient_id,
          optional: true,
          title: 'SMART App Launch Patient ID (Dinner Adaptive)',
          type: 'text',
          description: %(
            Patient instance ID to be provided by Inferno as the patient as a part of the SMART App Launch.
          ),
          default: 'pat015'
    input :adaptive_smart_fhir_context,
          optional: true,
          title: 'SMART App Launch fhirContext (Dinner Adaptive)',
          type: 'textarea',
          description: %(
            References to be provided by Inferno as the fhirContext as a part of the SMART App
            Launch. These references help determine the behavior of the app. Referenced instances
            may be provided in the "EHR-available resources" input.
          ),
          default: JSON.pretty_generate([{ reference: 'Coverage/cov015' },
                                         { reference: 'DeviceRequest/devreqe0470' }])
    input :adaptive_ehr_bundle,
          optional: true,
          title: 'EHR-available resources (Dinner Adaptive)',
          type: 'textarea',
          description: %(
            Resources available from the EHR needed to drive the dinner adaptive workflow.
            Formatted as a FHIR bundle that contains resources, each with an ID property populated. Each
            instance present will be available for retrieval from Inferno at the endpoint:
            <fhir-base>/<resource type>/<instance id>
          )

    def example_client_jwt_payload_part
      Base64.strict_encode64({ inferno_client_id: client_id }.to_json).delete('=')
    end

    run do
      # validate relevant inputs and provide warnings if they are bad
      warning do
        if adaptive_smart_fhir_context
          assert_valid_json(adaptive_smart_fhir_context,
                            'The **SMART App Launch fhirContext** input is not valid JSON, so it will not be included in
                            the access token response.')
        end
      end

      warning do
        if adaptive_ehr_bundle
          assert_valid_json(adaptive_ehr_bundle,
                            'The **EHR-available resources** input is not valid JSON, so no tester-specified instances
                              will be available to access from Inferno.')
          assert(FHIR.from_contents(adaptive_ehr_bundle).is_a?(FHIR::Bundle),
                 'The **EHR-available resources** input does not contain a FHIR Bundle, so no tester-specified instances
                 will be available to access from Inferno.')
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
        message: %(
          ### SMART App Launch

          #{launch_prompt}

          #{inferno_prompt_cont if smart_app_launch == 'ehr'}

          ### Adaptive Questionnaire Retrieval

          1. **Questionnaire Package Request**:
            - Inferno will expect the SMART App to invoke the DTR Questionnaire Package operation by sending a POST
            request to

            `#{questionnaire_package_url}`

            - Inferno will respond with an empty adaptive questionnaire.

          2. **Initial Next Question Request**:
            - After receiving the questionnaire package, invoke the `$next-question` operation by sending
            a POST request to the following endpoint to retrieve the first set of questions:

              `#{next_url}`.

            - Inferno will respond with the initial set of questions.

          ### Pre-population

          Inferno will then wait for the client to complete Questionnaire pre-population. The client should make FHIR
          GET requests using service base path:

          `#{fhir_base_url}`

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          an `Authorization` header with value:

          ```
          Bearer eyJhbGciOiJub25lIn0.#{example_client_jwt_payload_part}.
          ```

          ### Continuing the Tests

          When the DTR application has finished loading the Questionnaire,
          including any clinical data requests to support pre-population,
          [Click here](#{resume_pass_url}?client_id=#{client_id}) to continue.
        )
      )
    end
  end
end
