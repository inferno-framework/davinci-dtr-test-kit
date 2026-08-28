require_relative '../../../cross_suite/generated_profile_metadata'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireStandardMustSupportTest < Inferno::Test
      include QuestionnaireHelper

      MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_std_questionnaire')

      id :dtr_v220_payer_questionnaire_standard_must_support
      title 'Server provides standard Questionnaire must support elements and extensions'
      description %(
        This test confirms that all must support elements added in the
        [DTR Standard Questionnaire](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-std-questionnaire.html)
        profile have been observed cumulatively across standard Questionnaires returned
        during previous `$questionnaire-package` tests. Common inherited Questionnaire
        elements are evaluated separately.

        This includes the following elements:
        - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n        - ")}
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-2'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        questionnaires = questionnaires_from_operation_responses(requests)
        skip_if questionnaires.blank?, 'No Questionnaires were found in $questionnaire-package responses.'

        standard_questionnaires = questionnaires.reject { |questionnaire| adaptive_questionnaire?(questionnaire) }
        omit_if standard_questionnaires.blank?, 'The server did not return any standard Questionnaires.'

        assert_must_support_elements_present(standard_questionnaires, MUST_SUPPORT_METADATA.profile_url,
                                             metadata: MUST_SUPPORT_METADATA)
      end
    end
  end
end
