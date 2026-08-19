require_relative '../validation_test'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnairePackageRequestValidationTest < Inferno::Test
      include DaVinciDTRTestKit::ValidationTest

      id :dtr_v220_payer_questionnaire_package_request_validation
      title '$questionnaire-package request input is valid'
      description %(
        This test validates that each tester-provided $questionnaire-package request body
        conforms to the [DTR Questionnaire Package Input Parameters profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-input-parameters.html).
      )
      simulation_verification

      input :questionnaire_package_request_parameters

      run do
        request_bodies = Array.wrap(parsed_json_if_valid(questionnaire_package_request_parameters, continue: false))

        omit_if request_bodies.empty?, 'No $questionnaire-package requests provided.'

        request_bodies.each_with_index do |request_body, index|
          fhir_obj = begin
            FHIR.from_contents(request_body.to_json)
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

        assert_no_error_messages('Non-conformant $questionnaire-package request input. See Messages for details.')
      end
    end
  end
end
