require_relative '../../../tags'
require_relative 'contained_binary_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ContainedBinaryTest < Inferno::Test
      include ContainedBinaryValidation

      id :dtr_v220_payer_contained_binary
      title 'Contained Binary resources are PDFs or safe XHTML'
      description %(
        This test verifies that Binary resources contained in QuestionnaireResponses
        returned from the `$questionnaire-package` or `$next-question` operations are
        either PDFs or XHTML pages without active content or scripts.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-160'

      run do
        questionnaire_package_requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        next_question_requests = load_tagged_requests(NEXT_TAG)
        skip_if questionnaire_package_requests.blank? && next_question_requests.blank?,
                'No $questionnaire-package or $next-question requests were made'

        questionnaire_responses =
          questionnaire_responses_from_questionnaire_package_requests(questionnaire_package_requests) +
          questionnaire_responses_from_next_question_requests(next_question_requests)
        binaries = contained_binaries(questionnaire_responses)

        skip_if binaries.blank?, 'No Binary resources were contained in QuestionnaireResponses'

        invalid_binaries = binaries.reject { |binary| contained_binary_is_safe?(binary) }
        assert invalid_binaries.empty?,
               'Contained Binary resources must be PDFs or safe XHTML pages without active content or scripts.'
      end

      def questionnaire_responses_from_questionnaire_package_requests(requests)
        requests.filter_map do |request|
          parameters = response_resource(request)
          assert parameters.is_a?(FHIR::Parameters), 'Response is not a Parameters resource'

          questionnaire_response_from_package_bundle(parameters.parameter)
        end
      end

      def questionnaire_responses_from_next_question_requests(requests)
        requests.filter_map do |request|
          resource = response_resource(request)
          next resource if resource.is_a?(FHIR::QuestionnaireResponse)

          assert resource.is_a?(FHIR::Parameters), 'Response is not a Parameters resource'

          resource.parameter.find do |parameter|
            parameter.name == 'return' && parameter.resource.is_a?(FHIR::QuestionnaireResponse)
          end&.resource
        end
      end

      def response_resource(request)
        assert_valid_json(request.response_body, 'Response is not valid JSON')
        FHIR.from_contents(request.response_body)
      end

      def questionnaire_response_from_package_bundle(parameters)
        package_bundle = parameters.find { |parameter| parameter.name == 'packagebundle' }&.resource
        return unless package_bundle.is_a?(FHIR::Bundle)

        package_bundle.entry&.find { |entry| entry.resource.is_a?(FHIR::QuestionnaireResponse) }&.resource
      end
    end
  end
end
