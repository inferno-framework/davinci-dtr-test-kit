require_relative '../../../tags'
require_relative '../questionnaire_response_reference_validation'
require_relative 'contained_binary_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ContainedBinaryTest < Inferno::Test
      include ContainedBinaryValidation
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
        load_tagged_requests(QUESTIONNAIRE_TAG)
        load_tagged_requests(NEXT_TAG)
        omit_if requests.blank?,
                'No $questionnaire-package or $next-question requests were made'

        requests.each { |request| assert_valid_json(request.response_body, 'Response is not valid JSON') }
        questionnaire_responses = requests.flat_map { |request| questionnaire_responses_from_request(request) }
        binaries = contained_binaries(questionnaire_responses)

        omit_if binaries.blank?, 'No Binary resources were contained in QuestionnaireResponses'

        invalid_binaries = binaries.each_with_index.filter_map do |binary, index|
          [binary, index + 1] unless contained_binary_is_safe?(binary)
        end
        assert invalid_binaries.empty?,
               'The following Binary resources are not PDFs or safe XHTML fragments: ' \
               "#{invalid_binaries.map { |binary, index| binary_description(binary, index) }.join(', ')}"
      end

      def binary_description(binary, index)
        binary.id.present? ? "Binary `#{binary.id}`" : "contained Binary at position #{index}"
      end
    end
  end
end
