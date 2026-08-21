require_relative '../../../tags'
require_relative '../questionnaire_response_reference_validation'
require_relative 'contained_binary_validation'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ContainedBinaryTest < Inferno::Test
      include ContainedBinaryValidation
      include MultiRequestMessageHelper
      include QuestionnaireResponseReferenceValidation

      id :dtr_v220_payer_contained_binary
      title 'Contained Binary resources are PDFs or safe XHTML'
      description %(
        This test verifies that Binary resources contained in QuestionnaireResponses
        returned from the `$questionnaire-package` or `$next-question` operations are
        either PDFs or XHTML fragments that follow the FHIR R4 Narrative safety rules.
        XHTML must be a non-empty `<div>` fragment in the XHTML namespace and must not
        contain active content, scripts, external stylesheets, deprecated elements, or
        event-related attributes.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-160'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG, NEXT_TAG)
        omit_if requests.blank?,
                'No $questionnaire-package or $next-question requests were made'

        binary_found = false
        requests.each_with_index do |request, request_index|
          questionnaire_responses_from_request(request).each do |questionnaire_response|
            contained_binaries([questionnaire_response]).each do |binary|
              binary_found = true
              next if contained_binary_is_safe?(binary)

              add_request_message(
                'error',
                "#{binary_description(binary)} is not a PDF or safe XHTML fragment.",
                request_index
              )
            end
          end
        end

        omit_if !binary_found, 'No Binary resources were contained in QuestionnaireResponses'
        message = "#{requests_with_errors_prefix}" \
                  'Contained Binary resources must be PDFs or safe XHTML fragments. See Messages for details.'
        assert_no_error_messages(message)
      end

      def binary_description(binary)
        binary.id.present? ? "Binary `#{binary.id}`" : 'contained Binary without an id'
      end
    end
  end
end
