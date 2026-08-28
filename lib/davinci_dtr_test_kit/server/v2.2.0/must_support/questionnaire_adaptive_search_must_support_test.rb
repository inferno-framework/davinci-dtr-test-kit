require_relative '../../../cross_suite/generated_profile_metadata'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireAdaptiveSearchMustSupportTest < Inferno::Test
      include QuestionnaireHelper

      MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_questionnaire_adapt_search')

      id :dtr_v220_payer_questionnaire_adaptive_search_must_support
      title 'Server provides adaptive-search Questionnaire must support elements and extensions'
      description %(
        This test confirms that all must support elements and extensions defined in the
        [DTR Adaptive Questionnaire Search](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaire-adapt-search.html)
        profile have been observed cumulatively across adaptive-search Questionnaires
        returned during previous `$questionnaire-package` tests.

        This includes the following elements:
        - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n        - ")}
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-2'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        questionnaires = questionnaires_from_operation_responses(requests)
        skip_if questionnaires.blank?, 'No Questionnaires were found in $questionnaire-package responses.'

        adaptive_search_questionnaires = questionnaires.select do |questionnaire|
          adaptive_questionnaire?(questionnaire)
        end
        omit_if adaptive_search_questionnaires.blank?, 'The server did not return any adaptive-search Questionnaires.'

        assert_must_support_elements_present(adaptive_search_questionnaires, MUST_SUPPORT_METADATA.profile_url,
                                             metadata: MUST_SUPPORT_METADATA)
      end
    end
  end
end
