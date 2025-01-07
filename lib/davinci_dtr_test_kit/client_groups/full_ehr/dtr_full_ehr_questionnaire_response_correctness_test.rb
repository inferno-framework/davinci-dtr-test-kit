require_relative '../../dtr_questionnaire_response_validation'
require_relative '../../cql_test'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireResponseCorrectnessTest < Inferno::Test
    include DTRQuestionnaireResponseValidation
    include DaVinciDTRTestKit::CQLTest

    id :dtr_full_ehr_questionnaire_response_correctness
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      This test verifies that all the QuestionnaireResponse.item have the appropriate
      origin source extensions and that all required questions have been answered.
    )

    run do
      skip_if questionnaire_response.blank?, 'Completed QuestionnaireResponse input was blank'
      check_is_questionnaire_response(questionnaire_response)

      qr = FHIR.from_contents(questionnaire_response)
      questionnaire = if scratch[:static_questionnaire_bundles].nil?
                        Fixtures.questionnaire_for_test(id)
                      else
                        questionnaires = extract_questionnaires_from_bundles(scratch[:static_questionnaire_bundles])
                        questionnaires.find { |q| qr.questionnaire.end_with?(q.id) }
                      end

      skip_if questionnaire.blank?, "Couldn't find Questionnaire #{qr.questionnaire} to check the QuestionnaireResponse"

      expected_overrides = scratch[:static_questionnaire_bundles].nil? ? [] : ['PBD.2']
      scratch[:static_questionnaire_bundles] = nil

      check_origin_sources(questionnaire.item, qr.item, expected_overrides:)
      required_link_ids = extract_required_link_ids(questionnaire.item)
      check_answer_presence(qr.item, required_link_ids)
      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
