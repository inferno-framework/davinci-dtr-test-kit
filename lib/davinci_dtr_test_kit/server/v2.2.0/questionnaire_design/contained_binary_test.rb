require_relative '../../../tags'
require_relative '../questionnaire_operation_validation'
require_relative 'contained_binary_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ContainedBinaryTest < Inferno::Test
      include QuestionnaireOperationValidation
      include ContainedBinaryValidation

      id :dtr_v220_payer_contained_binary
      title 'Contained Binary resources are PDFs or safe XHTML'
      description %(
        This test verifies that Binary resources contained in QuestionnaireResponses
        returned from the `$questionnaire-package` or `$next-question` operations are
        either PDFs or XHTML pages without active content or scripts.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-160'

      def extract_questionnaire_responses(requests)
        resources = requests.filter_map do |request|
          FHIR.from_contents(request.response_body)
        rescue JSON::ParserError
          nil
        end
        resources.flat_map { |resource| questionnaire_responses_from_resource(resource) }
      end

      def questionnaire_responses_from_resource(resource)
        return [resource] if resource.is_a?(FHIR::QuestionnaireResponse)

        questionnaire_responses_from_bundles(extract_questionnaire_bundles(resource)) +
          questionnaire_responses_from_parameters(resource)
      end

      def questionnaire_responses_from_bundles(bundles)
        bundles.flat_map do |bundle|
          bundle.entry.filter_map do |entry|
            entry.resource if entry.resource.is_a?(FHIR::QuestionnaireResponse)
          end
        end
      end

      def questionnaire_responses_from_parameters(resource)
        return [] unless resource.is_a?(FHIR::Parameters)

        resource.parameter.filter_map do |parameter|
          parameter.resource if parameter.name == 'return' && parameter.resource.is_a?(FHIR::QuestionnaireResponse)
        end
      end

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        load_tagged_requests(NEXT_TAG)
        skip_if requests.blank?,
                'No $questionnaire-package or $next-question requests were made'

        questionnaire_responses = extract_questionnaire_responses(requests)
        binaries = contained_binaries(questionnaire_responses)

        skip_if binaries.blank?, 'No Binary resources were contained in QuestionnaireResponses'

        invalid_binaries = binaries.reject { |binary| contained_binary_is_safe?(binary) }
        assert invalid_binaries.empty?,
               'Contained Binary resources must be PDFs or safe XHTML pages without active content or scripts.'
      end
    end
  end
end
