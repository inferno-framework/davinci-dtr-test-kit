# frozen_string_literal: true

require 'date'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    module ValueSetExpansionValidation
      def value_set_expansion_errors(value_set, current_date: Date.current)
        errors = []
        unless value_set_expansion_current?(value_set, current_date)
          errors << expansion_timestamp_error(value_set, current_date)
        end

        inactive_expansion_codes(value_set).each do |code|
          errors << inactive_code_error(code)
        end

        errors
      end

      def value_set_expansion_current?(value_set, current_date = Date.current)
        timestamp = value_set.expansion&.timestamp
        timestamp.present? && Date.parse(timestamp.to_s) == current_date
      rescue Date::Error
        false
      end

      def inactive_expansion_codes(value_set)
        inactive_codes_in(value_set.expansion&.contains)
      end

      def inactive_codes_in(contains)
        Array(contains).flat_map do |code|
          inactive_code_array = code.inactive == true ? [code] : []
          inactive_code_array + inactive_codes_in(code.contains)
        end
      end

      def expansion_code_identifier(code)
        [code.system, code.code].compact.join('|').presence || code.display
      end

      def expansion_timestamp_error(value_set, current_date)
        timestamp = value_set.expansion&.timestamp
        return "expansion.timestamp is missing; expected current date `#{current_date}`" if timestamp.blank?

        "expansion.timestamp `#{timestamp}` is not the current date `#{current_date}`"
      end

      def inactive_code_error(code)
        identifier = expansion_code_identifier(code)
        return 'expansion contains an inactive code' if identifier.blank?

        "expansion contains inactive code `#{identifier}`"
      end
    end
  end
end
