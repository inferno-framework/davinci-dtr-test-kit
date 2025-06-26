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
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@38', 'hl7.fhir.us.davinci-dtr_2.0.1@210',
                          'hl7.fhir.us.davinci-dtr_2.0.1@244'

    def profile_url
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt'
    end

    def next_request_tag
      config.options[:next_tag]
    end

    def perform_questionnaire_reponses_validation(custom_questionnaires) # rubocop:disable Metrics/CyclomaticComplexity
      requests.each_with_index do |r, index|
        if r.url != next_url
          add_message('warning',
                      "Request #{index} made to wrong URL: #{r.url}. Should instead be to #{next_url}")
        end

        assert_valid_json(r.request_body)
        input_params = FHIR.from_contents(r.request_body)
        assert input_params.present?, 'Request does not contain a recognized FHIR object'

        qr = nil
        if input_params.is_a?(FHIR::QuestionnaireResponse)
          qr = input_params
        elsif input_params.is_a?(FHIR::Parameters)
          qr = input_params.parameter&.find do |param|
            param.name == 'questionnaire-response'
          end&.resource
        end

        assert qr.present?, 'QuestionnaireResponse resource not provided.'
        verify_basic_conformance(qr.to_json, profile_url)

        questionnaire = qr.contained.find { |res| res.resourceType == 'Questionnaire' }
        assert questionnaire, 'QuestionnaireResponse does not contained a Questionnaire'

        scratch[:contained_questionnaires] ||= []
        scratch[:contained_questionnaires] << questionnaire

        verify_contained_questionnaire(questionnaire, index, custom_questionnaires)
        check_missing_origin_sources(qr, index) if index == requests.length - 1

        expected_overrides = next_request_tag&.include?('custom') ? [] : ['PBD.2']
        check_origin_sources(questionnaire.item, qr.item, expected_overrides:, index:)

        required_link_ids = extract_required_link_ids(questionnaire.item)
        check_answer_presence(qr.item, required_link_ids, index)
      rescue Inferno::Exceptions::AssertionException => e
        prefix = e.message.include?('Workflow not') ? '' : "Request #{index}: "
        add_message('error', "#{prefix}#{e.message}")
        next
      end
    end

    def verify_contained_questionnaire(questionnaire, index, custom_questionnaires)
      return unless next_request_tag&.include?('custom')
      return unless index.positive? && custom_questionnaires.present?

      expected_questionnaire = custom_questionnaires[index - 1]
      return unless expected_questionnaire

      actual_items = questionnaire.to_hash['item']
      expected_items = expected_questionnaire['item']

      assert actual_items == expected_items, %(
        Invalid QuestionnaireResponse: the contained Questionnaire `item` does not match the expected content.
        **Expected**: #{expected_items.inspect}
        **Received**: #{actual_items.inspect}
      )
    end

    def verify_workflow_completion(custom_questionnaires)
      return unless next_request_tag&.include?('custom')

      assert requests.length > custom_questionnaires.length, %(
            Workflow not completed: expected #{custom_questionnaires.length + 1} next-question requests,
            but received #{requests.length}.
          )
    end

    run do
      load_tagged_requests next_request_tag
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'

      custom_questionnaires = []
      if next_request_tag&.include?('custom')
        begin
          custom_questionnaires = [JSON.parse(custom_next_question_questionnaires)].flatten
        rescue JSON::ParserError
          add_message(
            'error',
            'Workflow not completed: the provided questionnaires input for next-question requests is not valid JSON'
          )
        end
      end

      perform_questionnaire_reponses_validation(custom_questionnaires)
      verify_workflow_completion(custom_questionnaires)

      assert(messages.none? { |m| m[:type] == 'error' }, 'QuestionnaireResponse is not correct, see error message(s)')
    end
  end
end
