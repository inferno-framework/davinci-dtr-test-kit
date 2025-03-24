module DaVinciDTRTestKit
  class DTRCustomNextQuestionResponseValidationTest < Inferno::Test
    id :dtr_custom_next_questionnaire_validation
    title '[USER INPUT VERIFICATION] Custom Questionnaires for $next-question Responses are valid for this workflow'
    description %(
      Inferno will validate that the user-provided Questionnaire resources to be included in
      each `$next-question` response are correct for this workflow.

      The test verifies that:
      1. All provided Questionnaires have the same ID as the contained Questionnaire in the
         `QuestionnaireResponse` of the `$next-question` request.
      2. Each provided Questionnaire includes all previously presented questions along with
         the next question or set of questions.

      If any of these conditions are not met, the test will fail.
    )

    input :custom_next_question_questionnaires,
          title: 'Custom Questionnaire resources to include in each $next-question Response',
          description: %(
            Provide a JSON list of Questionnaire resources for Inferno to use when updating
            the contained Questionnaire in the `QuestionnaireResponse` received in each
            `$next-question` request.

            Each `$next-question` request will correspond to the next item in the provided list,
            and Inferno will replace the contained Questionnaire with the corresponding resource
            before returning the updated `QuestionnaireResponse`.

            The provided Questionnaires must contain the next question or set of questions in
            sequence, ensuring a proper progression of the adaptive questionnaire workflow.
          ),
          type: 'textarea'

    def next_request_tag
      config.options[:next_tag]
    end

    def extract_link_ids(questionnaire_items)
      questionnaire_items&.each_with_object([]) do |item, link_ids|
        link_ids << item.linkId

        link_ids.concat(extract_link_ids(item.item)) if item.item.present?
      end
    end

    def validate_correctness_of_custom_next_questionnaire(custom_questionnaire, contained_questionnaire)
      custom_items_link_ids = extract_link_ids(custom_questionnaire.item) || []
      contained_items_link_ids = extract_link_ids(contained_questionnaire.item) || []
      missing_items_ids = contained_items_link_ids - custom_items_link_ids

      error_msg = %(
        Custom Questionnaire must include all previous questions along with the next question or set of questions.
      )
      add_message('error', error_msg) if custom_items_link_ids.length <= contained_items_link_ids.length

      error_msg = %(
        Custom Questionnaire must include all previous questions. The following items are missing:
        questions with Link ID `#{missing_items_ids.to_sentence}`.
      )
      add_message('error', error_msg) if missing_items_ids.present?
    end

    run do
      load_tagged_requests next_request_tag
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'
      assert_valid_json custom_next_question_questionnaires, 'Custom $next-question Questionnaires is not valid JSON'

      skip_if scratch[:contained_questionnaires].nil?, %(
        Unable to validate user-provided Questionnaires: no valid `$next-question` requests
        containing a Questionnaire were received.
      )

      custom_questionnaires = [JSON.parse(custom_next_question_questionnaires)].flatten
      custom_questionnaires.each do |q|
        custom_questionnaire = FHIR.from_contents(q.to_json)
        assert custom_questionnaire, "The custom Questionnaire #{q[:id]} provided is not a valid FHIR resource"
        assert_resource_type(:questionnaire, resource: custom_questionnaire)

        contained_questionnaire = scratch[:contained_questionnaires].find { |cq| cq.id == custom_questionnaire.id }
        assert contained_questionnaire, %(
          Unable to validate the provided custom Questionnaire `#{q[:id]}`: no valid `$next-question` request
          was found containing a Questionnaire with a matching ID.
        )

        validate_correctness_of_custom_next_questionnaire(custom_questionnaire, contained_questionnaire)
      rescue Inferno::Exceptions::AssertionException => e
        add_message('error', "Questionnaire `#{q[:id]}`: #{e.message}")
        next
      end

      assert messages.none? { |message| message[:type] == 'error' },
             'Custom Questionnaire provided is not valid for this workflow'
    end
  end
end
