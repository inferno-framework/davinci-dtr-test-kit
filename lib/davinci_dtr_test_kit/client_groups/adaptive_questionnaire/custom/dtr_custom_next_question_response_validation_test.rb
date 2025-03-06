module DaVinciDTRTestKit
  class DTRCustomNextQuestionResponseValidationTest < Inferno::Test
    id :dtr_custom_next_questionnaire_validation
    title '[USER INPUT VERIFICATION] Custom Questionnaire for $next-question Response is valid for this workflow'
    description %(
      Inferno will validate that the user-provided Questionnaire resource to include in the
      `$next-question` response is correct for this workflow.

      The test verifies that:
      1. The custom Questionnaire has the same ID as the contained Questionnaire in the
        QuestionnaireResponse of the `$next-question` request.
      2. The custom Questionnaire includes all previously presented questions along with
        the next question or set of questions.

      If any of these conditions are not met, the test will fail.
    )

    input :custom_next_question_questionnaire,
          title: 'Custom Questionnaire resource to include in the $next-question Response',
          description: %(
            A JSON Questionnaire resource may be provided here for Inferno to use when updating
            the contained Questionnaire in the QuestionnaireResponse received in the
            `$next-question` request. Inferno will replace the contained Questionnaire
            with the provided resource before returning the updated QuestionnaireResponse
            in the response. The provided Questionnaire must contain the next question
            or set of questions.
          ),
          type: 'textarea'

    def extract_link_ids(questionnaire_items)
      questionnaire_items&.each_with_object([]) do |item, link_ids|
        link_ids << item.linkId

        link_ids.concat(extract_link_ids(item.item)) if item.item.present?
      end
    end

    def validate_correctness_of_custom_next_questionnaire(custom_questionnaire, contained_questionnaire)
      error_msg = %(
        Custom Questionnaire ID does not match the contained Questionnaire ID in
        the QuestionnaireResponse of the $next-question request.
        Expected `#{contained_questionnaire.id}`, but received `#{custom_questionnaire.id}`
      )
      add_message('error', error_msg) if custom_questionnaire.id != contained_questionnaire.id

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
      omit_if custom_next_question_questionnaire.blank?, 'Next question or set of questions not provided for this round'
      skip_if scratch[:contained_questionnaire].blank?, %(
        Unable to validate next questionnaire provided: could not find a contained
        questionnaire in the $next-question request.
      )
      assert_valid_json custom_next_question_questionnaire, 'Custom $next-question Questionnaire is not valid JSON'

      custom_questionnaire = FHIR.from_contents(custom_next_question_questionnaire)
      contained_questionnaire = scratch[:contained_questionnaire]
      validate_correctness_of_custom_next_questionnaire(custom_questionnaire, contained_questionnaire)

      assert messages.none? { |message| message[:type] == 'error' },
             'Custom Questionnaire provided is not valid for this workflow'
    end
  end
end
