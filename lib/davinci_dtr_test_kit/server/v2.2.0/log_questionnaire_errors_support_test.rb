module DaVinciDTRTestKit
  module DTRPayerServerV220
    class LogQuestionnaireErrorsSupportTest < Inferno::Test
      id :dtr_v220_payer_log_questionnaire_errors_support
      title 'Verify $log-questionnaire-errors operation support'
      description %(
        This test verifies that the payer supports the
        [`Questionnaire/$log-questionnaire-errors` operation](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html).

        Inferno submits a representative, non-PHI error report containing a
        Questionnaire canonical and an OperationOutcome. The payer must respond
        with a successful HTTP response.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-1'

      input :url
      input :questionnaire_canonical,
            title: 'Questionnaire Canonical URL',
            description: 'Canonical URL of a Questionnaire supported by the payer.'

      def log_questionnaire_errors_parameters
        FHIR::Parameters.new(
          parameter: [
            FHIR::Parameters::Parameter.new(
              name: 'questionnaire',
              valueCanonical: questionnaire_canonical
            ),
            FHIR::Parameters::Parameter.new(
              name: 'operationOutcome',
              resource: FHIR::OperationOutcome.new(
                issue: [
                  FHIR::OperationOutcome::Issue.new(
                    severity: 'error',
                    code: 'processing',
                    diagnostics: 'Unable to evaluate a Questionnaire expression.'
                  )
                ]
              )
            )
          ]
        )
      end

      run do
        fhir_operation(
          "#{url.chomp('/')}/Questionnaire/$log-questionnaire-errors",
          body: log_questionnaire_errors_parameters,
          headers: { 'Content-Type': 'application/fhir+json' }
        )

        status = request.status.to_s
        assert status.start_with?('2'),
               "Expected a successful 2xx response to $log-questionnaire-errors, but received HTTP #{status}."
      end
    end
  end
end
