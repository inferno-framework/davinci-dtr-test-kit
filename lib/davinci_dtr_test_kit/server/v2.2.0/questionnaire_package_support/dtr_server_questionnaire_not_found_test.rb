module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRServerQuestionnaireNotFoundTest < Inferno::Test
      id :dtr_server_v220_payer_questionnaire_not_found
      title 'Questionnaire package response includes a warning for an unknown Questionnaire'
      description %(
        The DTR Questionnaire Package operation [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confdetails.html#ci-c-oper-9)
        requires the server to return a warning when a requested Questionnaire cannot be found.
        Inferno sends a tester-provided `$questionnaire-package` request that includes an unknown Questionnaire
        and verifies that the response contains the required warning.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-9'

      input :url,
            title: 'Payer FHIR Server Base Url',
            description: 'Base FHIR URL implementing the DTR server operations.'

      input :questionnaire_not_found_request,
            title: 'Questionnaire Package Request with Unknown Questionnaire',
            description: %(
              Provide a `Parameters` resource in JSON format for a
              `Questionnaire/$questionnaire-package` request that explicitly requests
              at least one Questionnaire known not to exist on the payer server.
            ),
            type: 'textarea'

      fhir_client do
        url :url
      end

      run do
        request = FHIR.from_contents(questionnaire_not_found_request)

        assert_resource_type(:parameters, resource: request)

        fhir_operation(
          '/Questionnaire/$questionnaire-package',
          body: request
        )

        assert_response_status(200)
        assert_resource_type(:parameters)

        outcome_parameter = Array(resource.parameter).find do |parameter|
          parameter.name == 'outcome'
        end

        assert outcome_parameter.present?,
               'The questionnaire-package response is missing the required `outcome` parameter.'

        outcome = outcome_parameter.resource

        assert outcome.present?,
               'The `outcome` parameter does not contain an OperationOutcome resource.'

        assert_resource_type(:operation_outcome, resource: outcome)

        has_warning = Array(outcome.issue).any? do |issue|
          issue.severity == 'warning'
        end

        assert has_warning,
               'The OperationOutcome in the `outcome` parameter does not contain a warning issue.'
      end
    end
  end
end
