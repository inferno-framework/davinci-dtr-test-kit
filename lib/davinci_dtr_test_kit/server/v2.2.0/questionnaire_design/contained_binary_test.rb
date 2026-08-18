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
        This test verifies that Binary resources contained in Questionnaires returned
        from the `$questionnaire-package` operation are either PDFs or XHTML pages
        without active content or scripts.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-160'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.blank?, 'No $questionnaire-package requests were made'

        questionnaires = requests.flat_map do |request|
          resource = FHIR.from_contents(request.response_body)
          bundles = extract_questionnaire_bundles(resource)
          extract_questionnaires_from_bundles(bundles)
        rescue JSON::ParserError
          []
        end
        binaries = contained_binaries(questionnaires)

        skip_if binaries.blank?, 'No contained Binary resources were returned'

        invalid_binaries = binaries.reject { |binary| contained_binary_is_safe?(binary) }
        assert invalid_binaries.empty?,
               'Contained Binary resources must be PDFs or safe XHTML pages without active content or scripts.'
      end
    end
  end
end
