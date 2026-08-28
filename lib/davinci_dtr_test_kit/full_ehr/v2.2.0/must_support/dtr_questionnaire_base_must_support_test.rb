require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../cross_suite/generated_profile_metadata'

module DaVinciDTRTestKit
  class DTRFullEHRV220QuestionnaireBaseMustSupportTest < Inferno::Test
    include QuestionnaireHelper

    MUST_SUPPORT_METADATA = GeneratedProfileMetadata.for('v2.2.0', 'dtr_base_questionnaire')

    id :dtr_full_ehr_v220_questionnaire_base_must_support
    title 'Client supports base Questionnaire must support elements and extensions'
    description %(
      This test confirms that all must support elements and extensions defined on the
      [DTR Base Questionnaire](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-base-questionnaire.html)
      profile and its parents have been observed across all completed Questionnaires during
      previous tests. Note that Questionnaires from test scenarios where the Questionnaire
      was not completed, e.g., due to errors within referenced CQL, are not included in this
      analysis. During execution of those previous tests, testers attested to the correct
      display of, interaction with, and population of the Questionnaires as controlled by
      the elements aand extensions present in those Questionnaires.

      This includes the following elements:
      - #{MUST_SUPPORT_METADATA.must_support_strings.join("\n      - ")}
    )
    simulation_verification

    def target_tags
      [CLIENT_QUESTIONNAIRE_MUST_SUPPORT]
    end

    run do
      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'Requests must be made prior to running this test'

      questionnaires = questionnaires_from_operation_responses(requests)
      skip_if questionnaires.blank?, 'No Questionnaires found to evaluate in operation responses.'

      assert_must_support_elements_present(questionnaires.compact, MUST_SUPPORT_METADATA.profile_url,
                                           metadata: MUST_SUPPORT_METADATA)
    end
  end
end
