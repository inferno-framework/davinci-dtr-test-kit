# frozen_string_literal: true

require_relative 'value_set_expansion_validation'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ValueSetExpansionTest < Inferno::Test
      include ValueSetExpansionValidation

      id :dtr_v220_payer_value_set_expansion
      title 'ValueSet expansions use the current date and active codes'
      description %(
        This test verifies that ValueSets returned from `ValueSet/$expand` use the
        current date as their expansion timestamp and contain only active codes,
        including codes nested within the expansion hierarchy.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-5'

      run do
        value_sets = expanded_value_sets
        skip_if value_sets.empty?, 'No expanded ValueSet resources were returned.'

        errors = value_sets.flat_map.with_index do |value_set, index|
          value_set_expansion_errors(value_set).map do |error|
            "ValueSet #{index + 1}: #{error}"
          end
        end

        error_message = 'ValueSet expansions must use the current date and contain only active codes:'
        assert errors.empty?, [error_message, errors.join("\n")].join("\n")
      end

      private

      def expanded_value_sets
        load_tagged_requests(VALUE_SET_EXPAND_TAG).filter_map do |request|
          resource = FHIR.from_contents(request.response_body)
          resource if resource.is_a?(FHIR::ValueSet)
        rescue JSON::ParserError, FHIR::ClientException
          nil
        end
      end
    end
  end
end
