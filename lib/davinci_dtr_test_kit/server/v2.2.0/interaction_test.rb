require_relative 'client_simulation'
require_relative '../../urls'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class InteractionTest < Inferno::Test
      include ClientSimulation
      include URLs

      MANUAL_MODE = 'manual_mode'.freeze
      CLIENT_MODE = 'client_mode'.freeze

      id :dtr_v220_payer_interaction
      title 'Request Questionnaires'
      description %(
        During this test, Inferno will simulate a DTR Client and make requests against
        the payer endpoint to retrieve and complete questionnaires, including
        - the `Questionnaire/$questionnaire-package` operation
        - the `Questionnaire/$next-question` operation
        - the `ValueSet/$expand` operation

        The tester will provide the details of the requests for Inferno to use, including
        - A list of `$questionnaire-package` request parameters: Inferno will invoke the
          `$questionnaire-package` once per provided request body. Inferno will look
          for the following entries withing package bundles for follow-up requests:
          - Unexpanded ValueSets: Inferno will issue a `ValueSet/$expand` request for each.
          - Adaptive Questionnaires: Inferno will attempt to complete the form using the
            `Questionnaire/$next-question` operation using answers from tester-provided
            QuestionnaireResponse templates.
        - A list of QuestionnaireResponse templates: When an adaptive form is returned in
          a `$questionnaire-package` response, Inferno will find a matching template from
          this list based on the Questionnaire and use the answers to construct a sequence
          of `$next-question` calls.

        Requests made during this test are tagged for analysis in subsequent tests.
      )
      config options: { accepts_multiple_requests: true }

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'
      input :request_mode,
            title: 'DTR Request Mode',
            description: %(
              Choose how Inferno generates requests:

              **Manual mode:** Inferno generates requests from supplied JSON.

              **Client mode:** Inferno proxies requests from a tester-controlled DTR client.
            ),
            type: 'radio',
            default: MANUAL_MODE,
            options: {
              list_options: [
                {
                  label: 'Manual mode',
                  value: MANUAL_MODE
                },
                {
                  label: 'Client mode',
                  value: CLIENT_MODE
                }
              ]
            }
      # We put '(required)*' in the titles, because actually required inputs are incompatible with enable_when
      input :questionnaire_package_request_parameters,
            title: '$questionnaire-package Request Parameters (required)*',
            description: %(
              Tester-provided list of one or more $questionnaire-package requests each
              as a Parameters resource in json format. Inferno will call the
              `Questionnaire/$questionnaire-package` operation once for each
              with the request as the body of the invocation.
            ),
            type: 'textarea',
            optional: true,
            enable_when: { input_name: 'request_mode', value: MANUAL_MODE }
      input :questionnaire_response_templates,
            title: 'QuestionnaireResponse Templates for $next-question requests (required)*',
            description: %(
              Tester-provided list of one or more QuestionnaireResponse resources in json format
              that Inferno will use to populate answers for adaptive forms for the purpose
              of building `Questionnaire/$next-question` requests to complete these forms.
              If not provided, no `$next-question` requests will be performed.
            ),
            type: 'textarea',
            optional: true,
            enable_when: { input_name: 'request_mode', value: MANUAL_MODE }
      input :dtr_client_access_token,
            title: 'DTR Client Access Token (required)*',
            description: %(
              In DTR Client Mode, bearer token used to identify requests from a tester-controlled DTR client.
            ),
            optional: true,
            enable_when: { input_name: 'request_mode', value: CLIENT_MODE }
      input :backend_services_smart_auth_info

      run do
        if request_mode == CLIENT_MODE
          skip_if dtr_client_access_token.blank?, 'A DTR Client Access Token is required for DTR Client mode.'

          wait(
            identifier: dtr_client_access_token,
            timeout: 1200,
            message: %(
              **Tester-Controlled DTR Client Flow**

              Send DTR requests from the client to Inferno while this test is waiting.
              Include `Authorization: Bearer #{dtr_client_access_token}` on every request.

              - Questionnaire Package: `#{questionnaire_package_url}`
              - Next Question: `#{next_url}`
              - ValueSet Expand: `#{fhir_base_url}/ValueSet/$expand`

              Inferno will forward each request to the payer server, return the payer response to the
              client, and use the recorded interaction in subsequent tests.

              **[Click here](#{resume_pass_url}?token=#{dtr_client_access_token})** after the client workflow is
              complete.
            )
          )
        else
          skip_if questionnaire_package_request_parameters.blank?,
                  '$questionnaire-package Request Parameters input is required for Manual mode'

          parameters = extract_fhir_parameters(questionnaire_package_request_parameters)
          templates = extract_fhir_questionnaire_response_templates(questionnaire_response_templates)
          parameters.each { |parameter| questionnaire_interaction(url, parameter, templates) }
        end
      end

      def extract_fhir_parameters(questionnaire_package_request_parameters)
        parameters_list = Array.wrap(parsed_json_if_valid(questionnaire_package_request_parameters,
                                                          'Provided well-formed $questionnaire-package bodies.',
                                                          continue: false))
        parameters_list.map.with_index do |entry, index|
          if entry['resourceType'] == 'Parameters'
            FHIR::Parameters.new(entry)
          else
            add_message('warning', "skipping **$questionnaire-package Parameters** input entry #{index + 1}: " \
                                   'not a FHIR Parameters resource')
            nil
          end
        end.compact
      end

      def extract_fhir_questionnaire_response_templates(questionnaire_response_templates)
        return nil unless questionnaire_response_templates.present?

        questionnaire_response_list =
          Array.wrap(parsed_json_if_valid(questionnaire_response_templates,
                                          'Provided well-formed QuestionnaireResponse templates.',
                                          continue: false))
        questionnaire_response_list.map.with_index do |entry, index|
          if entry['resourceType'] == 'QuestionnaireResponse'
            FHIR::QuestionnaireResponse.new(entry)
          else
            add_message('warning', 'skipping **QuestionnaireResponse Templates for $next-question requests** ' \
                                   "input entry #{index + 1}: not a FHIR QuestionnaireResponse resource")
            nil
          end
        end.compact
      end
    end
  end
end
