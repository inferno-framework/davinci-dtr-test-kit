# frozen_string_literal: true

require_relative '../questionnaire_response_reference_validation'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireResponseReferencesTest < Inferno::Test
      include QuestionnaireResponseReferenceValidation

      id :dtr_v220_payer_questionnaire_response_references
      title 'QuestionnaireResponse references target contained or client FHIR resources'
      description %(
        This test verifies that every reference in each QuestionnaireResponse returned by
        `$questionnaire-package` or `$next-question` points to either a resource contained
        in that QuestionnaireResponse or a resource on the DTR client's FHIR endpoint.
        Relative references are interpreted relative to the DTR client's FHIR endpoint.
        To validate absolute references, provide the DTR Client FHIR Endpoint input.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-139'

      input :client_fhir_endpoint

      run do
        questionnaire_responses = returned_questionnaire_responses
        skip_if questionnaire_responses.empty?, 'No QuestionnaireResponse resources were returned.'

        invalid_references = questionnaire_responses.flat_map.with_index do |questionnaire_response, index|
          invalid_questionnaire_response_references(questionnaire_response, client_fhir_endpoint).map do |reference|
            "QuestionnaireResponse #{index + 1}: #{reference}"
          end
        end

        assert invalid_references.empty?,
               "References must target contained resources or the DTR client's FHIR endpoint:\n" \
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
