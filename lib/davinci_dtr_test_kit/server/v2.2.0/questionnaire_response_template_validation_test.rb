require_relative '../validation_test'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireResponseTemplateValidationTest < Inferno::Test
      include DaVinciDTRTestKit::ValidationTest

      id :dtr_v220_payer_questionnaire_response_template_validation
      title 'QuestionnaireResponse template input is valid'
      description %(
        This test validates that each tester-provided QuestionnaireResponse template
        conforms to the [DTR Questionnaire Response for adaptive form profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html).
      )
      simulation_verification

      input :questionnaire_response_templates, optional: true

      run do
        omit_if questionnaire_response_templates.nil?, 'No QuestionnaireResponse templates were provided.'

        questionnaire_responses = Array.wrap(parsed_json_if_valid(questionnaire_response_templates, continue: false))

        omit_if questionnaire_responses.blank?, 'No QuestionnaireResponse templates were provided.'

        questionnaire_responses.each_with_index do |response_template, index|
          fhir_obj = begin
            FHIR.from_contents(response_template.to_json)
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

        assert_no_error_messages('Non-conformant QuestionnaireResponse template input. See Messages for details.')
      end
    end
  end
end
