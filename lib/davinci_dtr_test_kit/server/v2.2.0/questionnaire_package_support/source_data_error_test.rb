# frozen_string_literal: true

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class SourceDataErrorTest < Inferno::Test
      id :dtr_v220_payer_source_data_error
      title 'Source data errors return a 4xx response with an OperationOutcome'
      description %(
        Inferno invokes `Questionnaire/$questionnaire-package` using a
        tester-provided request containing source data that the DTR server cannot
        resolve, such as an unknown coverage or context identifier. Inferno verifies
        that the server returns a 4xx response with an OperationOutcome.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-130'

      input :source_data_error_request,
            title: '$questionnaire-package Request with Invalid Source Data',
            description: %(
              Provide a `Parameters` resource in JSON format containing source data
              known to be unresolvable by the DTR server, such as an unknown coverage
              or context identifier.
            ),
            type: 'textarea'

      run do
        request = FHIR.from_contents(source_data_error_request)
        assert_resource_type(:parameters, resource: request)

        fhir_operation(
          '/Questionnaire/$questionnaire-package',
          body: request,
          headers: { 'Content-Type': 'application/fhir+json' }
        )

        assert_response_status((400..499).to_a)
        assert_resource_type(:operation_outcome)
      end
    end
  end
end
