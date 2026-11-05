require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../cross_suite/v2.2.0/questionnaire_response_must_support_metadata'
require_relative '../../../cross_suite/generated_profile_metadata'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnaireResponseBaseMustSupportTest < Inferno::Test
    include QuestionnaireHelper

    MUST_SUPPORT_METADATA = QuestionnaireResponseMustSupportMetadata.metadata_for(
      GeneratedProfileMetadata.for('v2.2.0', 'dtr_questionnaireresponse')
    )

    id :dtr_full_ehr_v220_questionnaire_response_base_must_support
    title 'Client supports base QuestionnaireResponse must support elements and extensions'
    description %(
      This test confirms that all must support elements and extensions defined on the
      [DTR Questionnaire Response](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse.html)
      profile and its parents have been observed across all QuestionnaireResponses sent by the
      client during previous tests, including within nested items at any depth.

      Two additions come from
      [conf-5](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-5),
      which requires form fillers to be able to display answers of all data types and the name of
      the response's source:
      - Answers of every data type allowed by `item.answer.value[x]` must be observed.
      - `source` must be observed, even though the profile does not flag it as must support.

      Inferno only sees the QuestionnaireResponses that the client sends in $next-question
      requests, so this analysis covers adaptive Questionnaires only. Every $next-question request
      contributes: an element populated in any of them counts as demonstrated.
      QuestionnaireResponses for standard Questionnaires are never sent to Inferno, so their
      display is covered by tester attestation during the interaction tests instead.

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

      assert_must_support_elements_present(flatten_questionnaire_response_items!(questionnaire_responses),
                                           MUST_SUPPORT_METADATA.profile_url, metadata: MUST_SUPPORT_METADATA)
    end
  end
end
