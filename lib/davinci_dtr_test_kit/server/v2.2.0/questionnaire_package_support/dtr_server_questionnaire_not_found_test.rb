require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRServerQuestionnaireNotFoundTest < Inferno::Test
      id :dtr_server_v220_payer_questionnaire_not_found
      title 'Questionnaire package response includes a warning for an unknown Questionnaire'
      description %(
        The DTR Questionnaire Package operation requires the server to return a warning
        when a requested Questionnaire cannot be found. Inferno adds an unknown Questionnaire
        to a previously made `$questionnaire-package` request and verifies that the
        response contains the required warning.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-9'

      QUESTIONNAIRE_NOT_FOUND_URL = 'https://inferno.health/Questionnaire/does-not-exist'.freeze

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'

      fhir_client do
        url :url
        auth_info :backend_services_smart_auth_info
      end

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?,
                'No $questionnaire-package requests were made in the Request Questionnaires test.'

        questionnaire_package_parameters = FHIR.from_contents(requests.first.request_body)

        assert_resource_type(:parameters, resource: questionnaire_package_parameters)

        questionnaire_package_parameters.parameter << FHIR::Parameters::Parameter.new(
          name: 'questionnaire',
          valueCanonical: QUESTIONNAIRE_NOT_FOUND_URL
        )

        fhir_operation(
          '/Questionnaire/$questionnaire-package',
          body: questionnaire_package_parameters
        )

        assert_valid_json(request.response_body)
        assert_resource_type(:parameters)
        assert_valid_resource

        outcome_parameter = resource.parameter.find do |parameter|
          parameter.name == 'outcome'
        end

        assert outcome_parameter.present?,
               'The questionnaire-package response is missing the required `outcome` parameter.'

        outcome = outcome_parameter.resource

        assert outcome.present?,
               'The `outcome` parameter does not contain an OperationOutcome resource.'

        assert_resource_type(:operation_outcome, resource: outcome)

        has_warning = outcome.issue.any? do |issue|
          issue.severity == 'warning'
        end

        assert has_warning,
               'The OperationOutcome in the `outcome` parameter does not contain a warning issue.'
      end
    end
  end
end
