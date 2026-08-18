# frozen_string_literal: true

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class InvalidQuestionnaireResponseTest < Inferno::Test
      id :dtr_v220_payer_invalid_questionnaire_response
      title 'Invalid QuestionnaireResponses return 400 with an OperationOutcome'
      description %(
        Inferno invokes `Questionnaire/$next-question` using a tester-provided
        QuestionnaireResponse that the DTR server considers invalid based on the
        rules in its contained Questionnaire. Inferno verifies that the server
        returns HTTP 400 with an OperationOutcome describing the error.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-147'

      input :invalid_questionnaire_response,
            title: 'Invalid QuestionnaireResponse',
            description: %(
              Provide a `QuestionnaireResponse` resource in JSON format that the DTR
              server will determine is invalid based on the rules in its contained
              Questionnaire.
            ),
            type: 'textarea'

      run do
        request = FHIR.from_contents(invalid_questionnaire_response)
        assert_resource_type(:questionnaire_response, resource: request)

        fhir_operation(
          '/Questionnaire/$next-question',
          body: request,
          headers: { 'Content-Type': 'application/fhir+json' }
        )

        assert_response_status(400)
        assert_resource_type(:operation_outcome)
        assert resource.issue.present?,
               'The OperationOutcome did not include an issue describing why the QuestionnaireResponse was invalid.'
      end
    end
  end
end
