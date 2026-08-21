require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../validation_test'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireResponseValidationTest < Inferno::Test
      include URLs
      include DaVinciDTRTestKit::ValidationTest
      include QuestionnaireOperationValidation

      id :dtr_v220_payer_questionnaire_response_validation

      title 'Verify that the response conforms to the DTR Questionnaire Package Output Parameters profile'
      description %(
        Inferno will verify that the payer server's response to the
        questionnaire-package operation conforms to the [Questionnaire Package
        Output Parameters
        profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-output-parameters.html).
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-10'
      input :url

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?, 'No $questionnaire-package requests were made'

        requests.each_with_index do |request, index|
          unless [200, 201].include? request.response[:status]
            add_message(
              'error',
              "Request #{index + 1} was unsuccessful."
            )
          end

          JSON.parse(request.response_body)

          resource = FHIR.from_contents(request.response_body)

          if resource.nil?
            add_message(
              'error',
              "Response #{index + 1} did not contain FHIR resources."
            )

            next
          end

          perform_questionnaire_package_response_validation(resource, index)
        rescue JSON::ParserError
          add_message(
            'error',
            "Response #{index + 1} contained invalid JSON."
          )
        end

        assert_no_error_messages('Not all responses were valid. See messages for details.')
      end
    end
  end
end
