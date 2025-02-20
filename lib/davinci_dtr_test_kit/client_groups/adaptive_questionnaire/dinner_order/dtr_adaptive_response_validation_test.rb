require_relative '../../urls'
require_relative '../../dtr_questionnaire_response_validation'

module DaVinciDTRTestKit
  class DTRAdaptiveResponseValidationTest < Inferno::Test
    include URLs
    include DTRQuestionnaireResponseValidation

    id :dtr_adaptive_response_validation
    title 'Adaptive QuestionnaireResponse is valid'
    description %(
      This test validates the conformance of the Adaptive QuestionnaireResponse to the
      [SDCQuestionnaireResponseAdapt](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt)
      structure. It verifies the presence of mandatory elements and that elements
      with required bindings contain appropriate values.

       It also ensures that all required questions are answered, and that the `origin.source`
      extension is correct for each answer:
        - `PBD.1` (Last Name) and `LOC.1` (Location): `auto`
        - `PBD.2` (First Name): `override`
        - `3` (all nested dinner questions): `manual`

      Note: For the initial next-question request, only the conformance to the profile is checked
      since neither the QuestionnaireResponse nor the contained Questionnaire will have any items,
      as no questions are yet known.
    )

    def profile_url
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt'
    end

    def next_request_tag
      config.options[:next_tag]
    end

    def custom_complete_questionnaire?
      !!config.options[:custom_complete_questionnaire]
    end

    run do
      load_tagged_requests next_request_tag
      skip_if request.blank?, 'A $next-question request must be made prior to running this test'

      assert request.url == next_url, "Request made to wrong URL: #{request.url}. Should instead be to #{next_url}"
      assert_valid_json(request.request_body)
      input_params = FHIR.from_contents(request.request_body)
      skip_if input_params.blank?, 'Request does not contain a recognized FHIR object'

      qr = nil
      if input_params.is_a?(FHIR::QuestionnaireResponse)
        qr = input_params
      elsif input_params.is_a?(FHIR::Parameters)
        qr = input_params.parameter&.find do |param|
          param.name == 'questionnaire-response'
        end&.resource
      end

      skip_if qr.nil?, 'QuestionnaireResponse resource not provided.'
      verify_basic_conformance(qr.to_json, profile_url)

      questionnaire = qr.contained.find { |res| res.resourceType == 'Questionnaire' }
      scratch[:contained_questionnaire] = questionnaire

      check_missing_origin_sources(qr) if custom_complete_questionnaire?
      expected_overrides = next_request_tag&.include?('custom') ? [] : ['PBD.2']
      check_origin_sources(questionnaire.item, qr.item, expected_overrides:)

      required_link_ids = extract_required_link_ids(questionnaire.item)
      check_answer_presence(qr.item, required_link_ids)

      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
