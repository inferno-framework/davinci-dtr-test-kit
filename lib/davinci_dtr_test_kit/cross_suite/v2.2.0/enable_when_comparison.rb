require 'date'

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

    # FHIR date, dateTime and instant, which may carry an offset and may stop at any precision
    DATE_TIME_PATTERN = /\A\d{4}(-\d{2}(-\d{2}([T ]\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?)?)?)?\z/
    # FHIR time, which carries no offset
    TIME_PATTERN = /\A\d{2}:\d{2}:\d{2}(\.\d+)?\z/

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
          primitives_equal?(answer_value, expected_value)
        end
      end

      # Two dates or times that name the same moment are equal however they are written, so they are
      # compared as moments rather than as the strings they arrive as.
      def primitives_equal?(answer_value, expected_value)
        temporal = temporal_comparison(answer_value, expected_value)
        temporal.nil? ? answer_value == expected_value : temporal.zero?
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
        comparison = comparison_result(answer_value, expected_value)
        return false if comparison.nil?

        ORDERING_COMPARISON_RESULTS[operator].include?(comparison)
      end

      # -1, 0 or 1, or nil for values that cannot be compared. Once either side is a date or a time,
      # only the temporal comparison applies: ordering a time of day against a date by their text
      # would put `10:00:00` before `2026-01-01` and mean nothing.
      def comparison_result(answer_value, expected_value)
        answer_moment = temporal_moment(answer_value)
        expected_moment = temporal_moment(expected_value)
        return ordered_moments(answer_moment, expected_moment) if answer_moment || expected_moment

        comparable_answer, comparable_expected = comparable_values(answer_value, expected_value)
        return nil if comparable_answer.nil? || comparable_expected.nil?

        comparable_answer <=> comparable_expected
      end

      def ordered_moments(answer_moment, expected_moment)
        return nil unless answer_moment && expected_moment && answer_moment.first == expected_moment.first

        answer_moment.last <=> expected_moment.last
      end

      # Compares two FHIR dates, dateTimes or times as moments, so that an offset, a trailing
      # fractional second or a shorter precision does not decide the answer. Returns nil unless both
      # values are temporal and of the same kind, since a time of day and a date name different things.
      def temporal_comparison(answer_value, expected_value)
        ordered_moments(temporal_moment(answer_value), temporal_moment(expected_value))
      end

      # [kind, moment] for a temporal value, or nil. A date that stops short of a full timestamp is
      # read as its first moment, so `2026` is `2026-01-01T00:00:00Z`.
      def temporal_moment(value)
        return nil unless value.is_a?(String)
        return [:time, seconds_since_midnight(value)] if TIME_PATTERN.match?(value)
        return nil unless DATE_TIME_PATTERN.match?(value)

        [:date_time, DateTime.parse(completed_date_time(value))]
      rescue ArgumentError
        nil
      end

      def seconds_since_midnight(value)
        hours, minutes, seconds = value.split(':')
        (hours.to_i * 3600) + (minutes.to_i * 60) + seconds.to_f
      end

      def completed_date_time(value)
        date, time = value.split(/[T ]/)
        year, month, day = date.split('-')
        "#{year}-#{month || '01'}-#{day || '01'}T#{time || '00:00:00'}"
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
