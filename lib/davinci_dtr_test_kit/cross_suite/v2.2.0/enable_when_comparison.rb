module DaVinciDTRTestKit
  # Compares an answer value from a QuestionnaireResponse against the value in an `enableWhen`
  # condition using the condition's operator. The `exists` operator is handled by the caller, which
  # knows whether an answer was found at all.
  module EnableWhenComparison
    # The results of `answer <=> expected` that satisfy each of the ordering operators
    ORDERING_COMPARISON_RESULTS = {
      '>' => [1],
      '<' => [-1],
      '>=' => [0, 1],
      '<=' => [-1, 0]
    }.freeze

    class << self
      def met?(operator, answer_value, expected_value)
        case operator
        when '='
          values_equal?(answer_value, expected_value)
        when '!='
          !values_equal?(answer_value, expected_value)
        when *ORDERING_COMPARISON_RESULTS.keys
          values_ordered?(operator, answer_value, expected_value)
        else
          false
        end
      end

      private

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

      def values_ordered?(operator, answer_value, expected_value)
        comparable_answer, comparable_expected = comparable_values(answer_value, expected_value)
        return false if comparable_answer.nil? || comparable_expected.nil?

        # `<=>` returns -1, 0, or 1, or nil for values that cannot be compared
        ORDERING_COMPARISON_RESULTS[operator].include?(comparable_answer <=> comparable_expected)
      end

      # Reduces the values to primitives that support `<=>`, or [nil, nil] if they cannot be compared.
      # Dates, dateTimes, and times remain ISO 8601 strings, which order correctly when both values
      # use the same precision and offset. Values that differ in either are not normalized.
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
end
