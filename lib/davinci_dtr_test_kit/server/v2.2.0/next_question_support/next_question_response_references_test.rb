# frozen_string_literal: true

require_relative '../questionnaire_response_reference_validation'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class NextQuestionResponseReferencesTest < Inferno::Test
      include QuestionnaireResponseReferenceValidation
      include MultiRequestMessageHelper

      id :dtr_v220_payer_next_question_response_references
      title 'Next-question QuestionnaireResponse references target contained or client FHIR resources'
      description %(
        This test verifies that every reference in each QuestionnaireResponse returned by
        `$next-question` points to either a resource contained in that QuestionnaireResponse
        or a resource on the DTR client's FHIR endpoint. Relative references are interpreted
        relative to the DTR client's FHIR endpoint. To validate absolute references, provide
        the DTR Client FHIR Endpoint input.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-139'

      input :client_fhir_endpoint, optional: true

      run do
        load_tagged_requests(NEXT_TAG)
        responses_by_request = requests.map { |request| questionnaire_responses_from_request(request) }
        skip_if responses_by_request.all?(&:empty?), 'No QuestionnaireResponse resources were returned.'
        absolute_references_returned = responses_by_request.flatten.any? do |response|
          questionnaire_response_has_absolute_reference?(response)
        end

        responses_by_request.each_with_index do |questionnaire_responses, request_index|
          questionnaire_responses.each do |questionnaire_response|
            invalid_questionnaire_response_references(questionnaire_response, client_fhir_endpoint).each do |reference|
              add_request_message('error', reference, request_index)
            end
          end
        end

        message = "#{requests_with_errors_prefix}" \
                  "References must target contained resources or the DTR client's FHIR endpoint. "
        assert_no_error_messages("#{message}See Messages for details.")

        skip_if client_fhir_endpoint.blank? && absolute_references_returned,
                'Absolute QuestionnaireResponse references were returned, but no DTR Client FHIR Endpoint was provided.'
      end
    end
  end
end
