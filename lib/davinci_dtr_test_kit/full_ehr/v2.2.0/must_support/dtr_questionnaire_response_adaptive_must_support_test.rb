require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../cross_suite/generated_profile_metadata'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnaireResponseAdaptiveMustSupportTest < Inferno::Test
    include QuestionnaireHelper

    MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_questionnaireresponse_adapt')

    id :dtr_full_ehr_v220_questionnaire_response_adaptive_must_support
    title 'Client supports adaptive QuestionnaireResponse must support elements and extensions'
    description %(
      This test confirms that all must support elements added in the
      [DTR Questionnaire Response for adaptive form](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html)
      profile have been observed across all QuestionnaireResponses sent by the client in
      $next-question requests during previous tests. This does not include must support elements
      flagged within the
      [DTR Questionnaire Response](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse.html)
      profile. The adaptive profile adds a single, required element: the in-progress adaptive
      Questionnaire contained within the QuestionnaireResponse. Correct display of the
      QuestionnaireResponse details and answers is covered by tester attestation during the
      interaction tests.

      This includes the following elements:
      - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n      - ")}
    )

    def target_tags
      [CLIENT_NEXT_TAG]
    end

    run do
      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'Requests must be made prior to running this test.'

      questionnaire_responses = questionnaire_responses_from_operation_requests(requests)
      skip_if questionnaire_responses.blank?,
              'No QuestionnaireResponses found to evaluate in $next-question requests.'

      assert_must_support_elements_present(questionnaire_responses_with_flattened_items(questionnaire_responses),
                                           MUST_SUPPORT_METADATA.profile_url, metadata: MUST_SUPPORT_METADATA)
    end
  end
end
