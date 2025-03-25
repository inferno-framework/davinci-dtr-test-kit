require_relative '../../dtr_questionnaire_response_validation'
require_relative '../../fixtures'

module DaVinciDTRTestKit
  class DTRQuestionnaireResponsePrepopulationTest < Inferno::Test
    include DTRQuestionnaireResponseValidation

    id :dtr_qr_prepopulation
    title 'QuestionnaireResponse pre-population and user overrides are conformant'
    description %(
      This test validates the conformance of the client's pre-population of the QuestionnaireResponse.

      It verifies:

      1. All items that should be pre-populated by CQL execution have an answer
      2. Pre-populated answers the tester was not directed to override have
         the origin.source extension set to 'auto' and an answer equivalent to
         from the expected result from execution of the CQL on Inferno's data.
      3. Pre-populated answers the tester was directed to override have
         the origin.source extension set to 'override' and an answer different
         from the expected result from execution of the CQL on Inferno's data.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@173', 'hl7.fhir.us.davinci-dtr_2.0.1@174',
                          'hl7.fhir.us.davinci-dtr_2.0.1@176', 'hl7.fhir.us.davinci-dtr_2.0.1@178',
                          'hl7.fhir.us.davinci-dtr_2.0.1@207'

    run do
      questionnaire_response_json = request.request_body
      check_is_questionnaire_response(questionnaire_response_json)
      questionnaire_response = FHIR.from_contents(questionnaire_response_json)
      if config.options[:adaptive]
        questionnaire = questionnaire_response.contained.find { |res| res.resourceType == 'Questionnaire' }
        assert questionnaire, 'Adaptive QuestionnaireResponse must have a contained Questionnaire resource.'

        check_missing_origin_sources(questionnaire_response) if config.options[:custom]

        expected_overrides = config.options[:custom] ? [] : ['PBD.2']
        check_origin_sources(questionnaire.item, questionnaire_response.item, expected_overrides:)

        required_link_ids = extract_required_link_ids(questionnaire.item)
        check_answer_presence(questionnaire_response.item, required_link_ids)

        assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
      else
        questionnaire = Fixtures.questionnaire_for_test(id)
        response_template = Fixtures.questionnaire_response_for_test(id)
        validate_questionnaire_pre_population(questionnaire, response_template, questionnaire_response)
      end
    end
  end
end
