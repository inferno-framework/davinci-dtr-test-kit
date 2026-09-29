require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../cross_suite/v2.2.0/questionnaire_response_display_must_support'
require_relative '../../../cross_suite/generated_profile_metadata'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnaireResponseBaseMustSupportTest < Inferno::Test
    include QuestionnaireHelper

    MUST_SUPPORT_METADATA = QuestionnaireResponseDisplayMustSupport.metadata_for(
      GeneratedProfileMetadata.for('v2.2.0', 'dtr_questionnaireresponse')
    )

    id :dtr_full_ehr_v220_questionnaire_response_base_must_support
    title 'Client supports base QuestionnaireResponse must support elements and extensions'
    description %(
      This test confirms that the elements of the
      [DTR Questionnaire Response](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse.html)
      profile that DTR requires form fillers to be able to display
      ([conf-5](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/confexpectations.html#ci-c-conf-5))
      have been observed populated across all QuestionnaireResponses sent by the client during
      previous tests: the Questionnaire reference and its display title, the `authored` date, the
      `author`, each item's `text`, and answers of every data type, including within nested items.

      Inferno only sees the QuestionnaireResponses that the client sends in $next-question
      requests, so this analysis covers adaptive Questionnaires only. Every $next-question request
      in each adaptive workflow contributes: an element populated in any of them counts as
      demonstrated. QuestionnaireResponses for standard Questionnaires are never sent to Inferno,
      so their display is covered by tester attestation during the interaction tests instead.

      This mechanical check is deliberately narrower than the profile's full must support set,
      which conf-5 does not require to be populated. The remaining must support elements and
      extensions (e.g., the coverage, context, and intendedUse extensions, `identifier`,
      `subject`, and the answer `origin` extension) are covered by tester attestation, as is
      display of the `source` name, which conf-5 lists but the profile does not flag as must
      support.

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
