module DaVinciDTRTestKit
  # Determines whether a QuestionnaireResponse has answers for all of the required questions in the
  # Questionnaire that it is based on. Used by Inferno's simulated payer server to decide when a
  # QuestionnaireResponse for an adaptive form is complete, and by the client tests to verify that a
  # client does not ask for the next question until the current questions have been answered.
  #
  # Questions disabled by their `enableWhen` conditions are not considered required, and neither are
  # their descendants. When a question has multiple `enableWhen` conditions, at least one must be met
  # unless `enableBehavior` is `all`. When the referenced question has multiple answers, the condition
  # is met if any answer satisfies it. Answers are looked up by linkId anywhere in the
  # QuestionnaireResponse and are used even if the answered question is itself disabled.
  #
  # Evaluation of an `enableWhen` condition that references a question with multiple occurrences in
  # the QuestionnaireResponse (the same linkId appearing more than once, e.g. within a repeating
  # group) is not supported and raises DuplicateLinkIdError.
  module QuestionnaireResponseCompleteness
    # The results of `answer <=> expected` that satisfy each of the ordering operators
    ORDERING_COMPARISON_RESULTS = {
      '>' => [1],
      '<' => [-1],
      '>=' => [0, 1],
      '<=' => [-1, 0]
    }.freeze

    class DuplicateLinkIdError < StandardError
      def initialize(link_id)
        super("multiple questions with linkId `#{link_id}` are present in the QuestionnaireResponse, " \
              'so the `enableWhen` conditions referencing it cannot be evaluated.')
      end
    end

    # The Questionnaire contained within a QuestionnaireResponse, which for an adaptive form holds
    # the questions disclosed so far.
    def contained_questionnaire(questionnaire_response)
      questionnaire_response.contained&.find { |contained_resource| contained_resource.is_a?(FHIR::Questionnaire) }
    end

    def questionnaire_response_complete?(questionnaire, questionnaire_response)
      unanswered_required_link_ids(questionnaire, questionnaire_response).empty?
    end

    # The link ids of the required, enabled questions in the questionnaire that do not have an answer
    # in the questionnaire response. Questions nested within an unanswered required question or within
    # a disabled question are omitted.
    def unanswered_required_link_ids(questionnaire, questionnaire_response)
      Array(questionnaire.item).flat_map do |item|
        unanswered_required_link_ids_for_item(item, questionnaire_response.item, questionnaire_response)
      end
    end

    private

    def unanswered_required_link_ids_for_item(item, response_items, questionnaire_response)
      return [] unless item_enabled?(item, questionnaire_response)

      response_item = find_response_item(item, response_items)
      return [item.linkId] if required_and_unanswered?(item, response_item)

      Array(item.item).flat_map do |sub_item|
        unanswered_required_link_ids_for_item(sub_item, response_item&.item, questionnaire_response)
      end
    end

    def find_response_item(item, response_items)
      Array(response_items).find { |response_item| response_item.linkId == item.linkId }
    end

    def required_and_unanswered?(item, response_item)
      item.required == true && !answer_present?(response_item)
    end

    def answer_present?(response_item)
      # an answer value of `false` is a valid answer, so check for nil rather than presence
      Array(response_item&.answer).any? { |answer| !answer&.value.nil? }
    end

    # ***********************************************************************
    # enableWhen evaluation
    # ***********************************************************************

    def item_enabled?(item, questionnaire_response)
      conditions = Array(item.enableWhen)
      return true if conditions.empty?

      condition_results = conditions.map { |condition| enable_when_satisfied?(condition, questionnaire_response) }
      item.enableBehavior == 'all' ? condition_results.all? : condition_results.any?
    end

    def enable_when_satisfied?(condition, questionnaire_response)
      answer_values = answer_values_for_question(condition.question, questionnaire_response)
      return answer_values.any? == (condition.answer == true) if condition.operator == 'exists'

      answer_values.any? { |answer_value| condition_met?(condition.operator, answer_value, condition.answer) }
    end

    def answer_values_for_question(link_id, questionnaire_response)
      matching_items = find_response_items_by_link_id(Array(questionnaire_response.item), link_id)
      raise DuplicateLinkIdError, link_id if matching_items.length > 1

      Array(matching_items.first&.answer).map(&:value).compact
    end

    def find_response_items_by_link_id(response_items, link_id)
      response_items.flat_map do |response_item|
        nested_matches = find_response_items_by_link_id(Array(response_item.item), link_id)
        response_item.linkId == link_id ? [response_item] + nested_matches : nested_matches
      end
    end

    def condition_met?(operator, answer_value, expected_value)
      case operator
      when '='
        values_equal?(answer_value, expected_value)
      when '!='
        !values_equal?(answer_value, expected_value)
      when *ORDERING_COMPARISON_RESULTS.keys
        values_compare?(operator, answer_value, expected_value)
      else
        false
      end
    end

    def values_equal?(answer_value, expected_value)
      if answer_value.is_a?(FHIR::Coding) || expected_value.is_a?(FHIR::Coding)
        coding_equal?(answer_value, expected_value)
      elsif answer_value.is_a?(FHIR::Quantity) || expected_value.is_a?(FHIR::Quantity)
        quantity_equal?(answer_value, expected_value)
      elsif answer_value.is_a?(FHIR::Reference) || expected_value.is_a?(FHIR::Reference)
        reference_equal?(answer_value, expected_value)
      else
        answer_value == expected_value
      end
    end

    def coding_equal?(answer_value, expected_value)
      answer_value.is_a?(FHIR::Coding) && expected_value.is_a?(FHIR::Coding) &&
        answer_value.system == expected_value.system && answer_value.code == expected_value.code
    end

    def reference_equal?(answer_value, expected_value)
      answer_value.is_a?(FHIR::Reference) && expected_value.is_a?(FHIR::Reference) &&
        answer_value.reference == expected_value.reference
    end

    def quantity_equal?(answer_value, expected_value)
      quantity_units_match?(answer_value, expected_value) && answer_value.value == expected_value.value
    end

    def quantity_units_match?(answer_value, expected_value)
      answer_value.is_a?(FHIR::Quantity) && expected_value.is_a?(FHIR::Quantity) &&
        answer_value.system == expected_value.system && answer_value.code == expected_value.code &&
        (answer_value.system.present? || answer_value.unit == expected_value.unit)
    end

    def values_compare?(operator, answer_value, expected_value)
      comparable_answer, comparable_expected = comparable_values(answer_value, expected_value)
      return false if comparable_answer.nil? || comparable_expected.nil?

      # `<=>` returns -1, 0, or 1, or nil for values that cannot be compared
      ORDERING_COMPARISON_RESULTS[operator].include?(comparable_answer <=> comparable_expected)
    end

    # Reduces the values to primitives that support `<=>`, or [nil, nil] if they cannot be compared.
    # Dates, dateTimes, and times remain ISO 8601 strings, which order correctly when both values use
    # the same precision and offset. Values that differ in either are not normalized before comparison.
    def comparable_values(answer_value, expected_value)
      return comparable_quantity_values(answer_value, expected_value) if answer_value.is_a?(FHIR::Quantity)

      comparable = (answer_value.is_a?(Numeric) && expected_value.is_a?(Numeric)) ||
                   (answer_value.is_a?(String) && expected_value.is_a?(String))
      comparable ? [answer_value, expected_value] : [nil, nil]
    end

    def comparable_quantity_values(answer_value, expected_value)
      return [nil, nil] unless quantity_units_match?(answer_value, expected_value)

      [answer_value.value, expected_value.value]
    end
  end
end
