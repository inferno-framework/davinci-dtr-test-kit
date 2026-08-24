# frozen_string_literal: true

require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class NextQuestionResponseValidationTest < Inferno::Test
      NEXT_QUESTION_OUTPUT_PARAMETERS_PROFILE =
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-next-question-output-parameters|2.2.0'
      ADAPTIVE_QUESTIONNAIRE_RESPONSE_PROFILE =
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0'

      id :dtr_v220_payer_next_question_response_validation
      title 'Verify that the next-question response conforms to the DTR output profile'
      description %(
        Inferno verifies that each payer server response to the `$next-question`
        operation conforms to the [DTR Next Question Output Parameters profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-next-question-output-parameters.html)
        when it is a Parameters resource, or to the [DTR Questionnaire Response
        for adaptive form profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html)
        when it is a plain QuestionnaireResponse resource.
      )

      run do
        load_tagged_requests(NEXT_TAG)

        omit_if requests.blank?, 'No $next-question requests were made.'

        requests.each_with_index do |request, index|
          add_message('error', "Request #{index + 1} was unsuccessful.") unless [200, 201].include? request.status

          JSON.parse(request.response_body)
          resource = FHIR.from_contents(request.response_body)

          if resource.nil?
            add_message('error', "Response #{index + 1} did not contain FHIR resources.")
            next
          end

          perform_next_question_response_validation(resource, index)
        rescue JSON::ParserError
          add_message('error', "Response #{index + 1} contained invalid JSON.")
        end

        assert_no_error_messages('Not all responses were valid. See messages for details.')
      end

      def perform_next_question_response_validation(resource, index)
        case resource
        when FHIR::Parameters
          resource_is_valid?(
            resource:,
            profile_url: NEXT_QUESTION_OUTPUT_PARAMETERS_PROFILE,
            message_prefix: "Response #{index + 1}: "
          )
        when FHIR::QuestionnaireResponse
          resource_is_valid?(
            resource:,
            profile_url: ADAPTIVE_QUESTIONNAIRE_RESPONSE_PROFILE,
            message_prefix: "Response #{index + 1}: "
          )
        else
          add_message('error', "Response #{index + 1} was not a Parameters or QuestionnaireResponse resource.")
        end
      end
    end
  end
end
