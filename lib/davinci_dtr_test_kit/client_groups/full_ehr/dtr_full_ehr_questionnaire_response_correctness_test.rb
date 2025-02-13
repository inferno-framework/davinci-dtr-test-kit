require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireResponseCorrectnessTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_questionnaire_response_correctness
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      The QuestionnaireResponse aligns with the following expectations for the workflow. This includes checks for
      the presence of the following answers and their appropriate origin source extensions:

      - `PBD.1` (Last Name) and `LOC.1` (Location): `auto`
      - PBD.2 (First Name): `override`
      - `3` (all nested dinner questions): `manual`
    )

    run do
      skip_if questionnaire_response.nil?, 'Completed QuestionnaireResponse input was blank'
      check_is_questionnaire_response(questionnaire_response)

      qr = FHIR.from_contents(questionnaire_response)
      questionnaire = if config.options[:adaptive]
                        qr.contained.find do |res|
                          res.resourceType == 'Questionnaire'
                        end
                      else
                        Fixtures.questionnaire_for_test(id)
                      end
      # questionnaire = Fixtures.find_questionnaire('DinnerOrderStatic')
      check_origin_sources(questionnaire.item, qr.item, expected_overrides: ['PBD.2'])
      required_link_ids = extract_required_link_ids(questionnaire.item)
      check_answer_presence(qr.item, required_link_ids)
      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
