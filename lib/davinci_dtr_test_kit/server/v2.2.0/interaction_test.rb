require_relative 'client_simulation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class InteractionTest < Inferno::Test
      include ClientSimulation

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

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'
      input :questionnaire_package_request_parameters,
            title: '$questionnaire-package Request Parameters',
            description: %(
              Tester-provided list of one or more $questionnaire-package requests each
              as a Parameters resource in json format. Inferno will call the
              `Questionnaire/$questionnaire-package` operation once for each
              with the request as the body of the invocation.
            ),
            type: 'textarea'
      input :questionnaire_response_templates,
            title: 'QuestionnaireResponse Templates for $next-question requests',
            description: %(
              Tester-provided list of one or more QuestionnaireResponse resources in json format
              that Inferno will use to populate answers for adaptive forms for the purpose
              of building `Questionnaire/$next-question` requests to complete these forms.
              If not provided, no `$next-question` requests will be performed.
            ),
            type: 'textarea',
            optional: true
      input :backend_services_smart_auth_info

      run do
        parameters = extract_fhir_parameters(questionnaire_package_request_parameters)
        templates = extract_fhir_questionnaire_response_templates(questionnaire_response_templates)
        parameters.each { |parameter| questionnaire_interaction(url, parameter, templates) }
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
