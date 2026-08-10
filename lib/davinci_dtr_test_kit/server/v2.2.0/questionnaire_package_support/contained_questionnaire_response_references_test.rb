# frozen_string_literal: true

require_relative '../questionnaire_response_reference_validation'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ContainedQuestionnaireResponseReferencesTest < Inferno::Test
      include QuestionnaireResponseReferenceValidation

      id :dtr_v220_payer_contained_questionnaire_response_references
      title 'Contained QuestionnaireResponse references occur only in answer values'
      description %(
        This test verifies that a QuestionnaireResponse returned by `$questionnaire-package`
        or `$next-question` uses contained resource references only as
        `QuestionnaireResponse.item.answer.valueReference` values.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-141'

      run do
        questionnaire_responses = returned_questionnaire_responses
        skip_if questionnaire_responses.empty?, 'No QuestionnaireResponse resources were returned.'

        invalid_references = questionnaire_responses.flat_map.with_index do |questionnaire_response, index|
          invalid_contained_reference_locations(questionnaire_response).map do |reference|
            "QuestionnaireResponse #{index + 1}: #{reference}"
          end
        end

        assert invalid_references.empty?,
               "Contained resource references are permitted only in item.answer valueReference elements:\n" \
               "#{invalid_references.join("\n")}"
      end

      private

      def returned_questionnaire_responses
        questionnaire_responses_from_requests(
          Array(load_tagged_requests(QUESTIONNAIRE_TAG)) + Array(load_tagged_requests(NEXT_TAG))
        )
      end
    end
  end
end
