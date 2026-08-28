require_relative '../../../cross_suite/generated_profile_metadata'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireBaseMustSupportTest < Inferno::Test
      include QuestionnaireHelper

      MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_base_questionnaire')

      id :dtr_v220_payer_questionnaire_base_must_support
      title 'Server provides common DTR Questionnaire must support elements and extensions'
      description %(
        This test confirms that all must support elements and extensions defined in the
        [DTR Base Questionnaire](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-base-questionnaire.html)
        profile and its parents have been observed cumulatively across standard
        and adaptive Questionnaires returned during previous tests.

        This includes the following elements:
        - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n        - ")}
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-2'

      run do
        questionnaire_package_requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        next_question_requests = load_tagged_requests(NEXT_TAG)
        skip_if requests.blank?, 'Requests must be made prior to running this test.'

        questionnaires = questionnaires_from_operation_responses(
          questionnaire_package_requests,
          include_adaptive: false
        ) + questionnaires_from_operation_responses(next_question_requests)
        skip_if questionnaires.blank?, 'No standard or adaptive Questionnaires were found to evaluate.'

        assert_must_support_elements_present(questionnaires, MUST_SUPPORT_METADATA.profile_url,
                                             metadata: MUST_SUPPORT_METADATA)
      end
    end
  end
end
