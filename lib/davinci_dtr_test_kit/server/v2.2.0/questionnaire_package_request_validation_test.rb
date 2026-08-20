require_relative '../validation_test'
require_relative '../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnairePackageRequestValidationTest < Inferno::Test
      include DaVinciDTRTestKit::ValidationTest

      id :dtr_v220_payer_questionnaire_package_request_validation
      title '$questionnaire-package request is valid'
      description %(
        This test validates that each outgoing $questionnaire-package request body
        conforms to the [DTR Questionnaire Package Input Parameters profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-input-parameters.html).
        Inferno generates these request bodies from the provided test input.
      )
      simulation_verification

      run do
        requests = load_tagged_requests(QUESTIONNAIRE_TAG)

        omit_if requests.empty?, 'No $questionnaire-package requests were made.'

        requests.each_with_index do |request, index|
          fhir_obj = begin
            FHIR.from_contents(request.request_body)
          rescue StandardError
            nil
          end

          validate_resource(
            fhir_obj,
            :parameters,
            'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.2.0',
            index
          )
        end

        assert_no_error_messages('Non-conformant $questionnaire-package request. See Messages for details.')
      end
    end
  end
end
