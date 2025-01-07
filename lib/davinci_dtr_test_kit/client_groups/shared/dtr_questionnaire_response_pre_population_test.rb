require_relative '../../dtr_questionnaire_response_validation'
require_relative '../../fixtures'
require_relative '../../cql_test'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponsePrePopulationTest < Inferno::Test
    include DTRQuestionnaireResponseValidation
    include DaVinciDTRTestKit::CQLTest

    id :dtr_questionnaire_response_pre_population
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      This test validates the conformance of the client's pre-population of the QuestionnaireResponse.

      It verifies:

      1. All items that should be pre-populated by CQL execution have an answer.
      2. All items have the appropriate origin.source extension.
      3. All required questions are answered.
    )

    run do
      questionnaire_response_json = request.request_body
      check_is_questionnaire_response(questionnaire_response_json)
      questionnaire_response = FHIR.from_contents(questionnaire_response_json)
      questionnaire = nil
      expected_overrides = []
      if config.options[:adaptive]
        questionnaire = questionnaire_response.contained.find { |res| res.resourceType == 'Questionnaire' }
        assert questionnaire, 'Adaptive QuestionnaireResponse must have a contained Questionnaire resource.'

        expected_overrides = ['PBD.2']
      else
        questionnaire = if scratch[:static_questionnaire_bundles].nil?
                          Fixtures.questionnaire_for_test(id)
                        else
                          questionnaires = extract_questionnaires_from_bundles(scratch[:static_questionnaire_bundles])
                          questionnaires.find { |q| questionnaire_response.questionnaire.end_with?(q.id) }
                        end
        skip_if questionnaire.blank?,
                "Couldn't find Questionnaire #{questionnaire_response.questionnaire} to check the QuestionnaireResponse"

        expected_overrides = ['PBD.2'] if scratch[:static_questionnaire_bundles].present?
        scratch[:static_questionnaire_bundles] = nil
      end

      check_origin_sources(questionnaire.item, questionnaire_response.item, expected_overrides:)
      required_link_ids = extract_required_link_ids(questionnaire.item)
      check_answer_presence(questionnaire_response.item, required_link_ids)
      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
