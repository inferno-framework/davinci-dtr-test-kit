require_relative '../validation_test'
require_relative '../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireResponseTemplateValidationTest < Inferno::Test
      include DaVinciDTRTestKit::ValidationTest

      id :dtr_v220_payer_questionnaire_response_template_validation
      title '$next-question QuestionnaireResponse request is valid'
      description %(
        This test validates that each outgoing QuestionnaireResponse request to the
        `$next-question` operation
        conforms to the [DTR Questionnaire Response for adaptive form profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html).
        Inferno generates these request bodies from the provided test input.
      )
      simulation_verification

      run do
        requests = load_tagged_requests(NEXT_TAG)

        omit_if requests.empty?, 'No $next-question requests were made.'

        requests.each_with_index do |request, index|
          fhir_obj = begin
            FHIR.from_contents(request.request_body)
          rescue StandardError
            nil
          end

          validate_resource(
            fhir_obj,
            :questionnaire_response,
            'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0',
            index
          )
        end

        assert_no_error_messages(
          'Non-conformant $next-question QuestionnaireResponse request. See Messages for details.'
        )
      end
    end
  end
end
