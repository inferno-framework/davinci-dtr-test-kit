require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRFullEHRDinnerStaticQuestionnaireResponseCorrectnessTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_full_ehr_dinner_static_questionnaire_response_correctness
    title 'QuestionnaireResponse is correct for the workflow'
    description %(
      The QuestionnaireResponse aligns with the following expectations for the workflow. This includes checks for
      the presence of the following answers and their appropriate origin source extensions:

      - PBD.1 (Last Name): `auto`
      - PBD.2 (First Name): `override`
      - 3.1 (dinner choice): `manual`
    )

    run do
      skip_if questionnaire_response.nil?, 'Completed QuestionnaireResponse input was blank'
      check_is_questionnaire_response(questionnaire_response)

      questionnaire = Fixtures.questionnaire_for_test(id)
      # questionnaire = Fixtures.find_questionnaire('DinnerOrderStatic')
      qr = FHIR.from_contents(questionnaire_response)
      check_origin_sources(questionnaire.item, qr.item, expected_overrides: ['PBD.2'])
      required_link_ids = extract_required_link_ids(questionnaire.item)
      check_answer_presence(qr.item, required_link_ids)
      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
