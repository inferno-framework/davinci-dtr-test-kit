# frozen_string_literal: true

require_relative '../questionnaire_response_reference_validation'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ContainedQuestionnaireResponseReferencesTest < Inferno::Test
      include QuestionnaireResponseReferenceValidation
      include MultiRequestMessageHelper

      id :dtr_v220_payer_contained_questionnaire_response_references
      title 'Contained QuestionnaireResponse references occur only in answer values'
      description %(
        This test verifies that a QuestionnaireResponse returned by `$questionnaire-package`
        uses contained resource references only as
        `QuestionnaireResponse.item.answer.valueReference` values.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-140',
                            'hl7.fhir.us.davinci-dtr_2.2.0@spec-141'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        responses_by_request = requests.map { |request| questionnaire_responses_from_request(request) }
        skip_if responses_by_request.all?(&:empty?), 'No QuestionnaireResponse resources were returned.'

        responses_by_request.each_with_index do |questionnaire_responses, request_index|
          questionnaire_responses.each do |questionnaire_response|
            invalid_contained_reference_locations(questionnaire_response).each do |reference|
              add_request_message('error', reference, request_index)
            end
          end
        end

        message = "#{requests_with_errors_prefix}" \
                  'Contained resource references are permitted only in item.answer valueReference '
        assert_no_error_messages("#{message}elements. See Messages for details.")
      end
    end
  end
end
