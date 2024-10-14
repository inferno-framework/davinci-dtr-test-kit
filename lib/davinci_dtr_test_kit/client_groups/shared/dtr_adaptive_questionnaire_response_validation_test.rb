require_relative '../../urls'
require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRAdaptiveQuestionnaireResponseValidationTest < Inferno::Test
    include URLs
    include DTRQuestionnaireResponseValidation

    id :dtr_adaptive_questionnaire_response_validation
    title 'Adaptive QuestionnaireResponse is valid'
    description %(
      This test validates the conformance of the Adative QuestionnaireResponse to the
      [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt)
      structure.

       It also ensures that all required questions are answered, and that the `origin.source`
      extension is correct for each answer:
            - `PBD.1` (Last Name) and `LOC.1` (Location): `auto`
            - `PBD.2` (First Name): `override`
            - `3.1` (dinner choice): `manual`

      Note: For the initial next-question request, only the conformance to the profile is checked
      since neither the QuestionnaireResponse nor the contained Questionnaire will have any items,
      as no questions are yet known.
    )

    def profile_url
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt'
    end

    run do
      load_tagged_requests CLIENT_NEXT_TAG
      skip_if request.blank?, 'A $next-question request must be made prior to running this test'

      assert request.url == next_url, "Request made to wrong URL: #{request.url}. Should instead be to #{next_url}"
      assert_valid_json(request.request_body)
      input_params = FHIR.from_contents(request.request_body)
      skip_if input_params.blank?, 'Request does not contain a recognized FHIR object'

      questionnaire_response = input_params.parameter&.find { |param| param.name == 'questionnaire-response' }&.resource
      questionnaire = questionnaire_response&.contained&.find { |res| res.resourceType == 'Questionnaire' }
      skip_if questionnaire_response.nil?, 'QuestionnaireResponse resource not provided.'
      skip_if questionnaire.nil?, 'QuestionnaireResponse resource does not contain a Questionnaire resource.'

      verify_basic_conformance(questionnaire_response.to_json, profile_url)
      check_origin_sources(questionnaire.item, questionnaire_response.item, expected_overrides: ['PBD.2'])

      required_link_ids = questionnaire.item.flat_map do |item|
        item.item&.select(&:required)&.map(&:linkId)
      end.compact
      check_answer_presence(questionnaire_response.item, link_ids: required_link_ids)

      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
