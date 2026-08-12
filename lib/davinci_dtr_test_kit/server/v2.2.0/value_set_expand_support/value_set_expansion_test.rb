# frozen_string_literal: true

require_relative 'value_set_expansion_validation'
require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ValueSetExpansionTest < Inferno::Test
      include ValueSetExpansionValidation
      include MultiRequestMessageHelper

      id :dtr_v220_payer_value_set_expansion
      title 'ValueSet expansions use the current date and active codes'
      description %(
        This test verifies that ValueSets returned from `ValueSet/$expand` use the
        current date as their expansion timestamp and contain only active codes,
        including codes nested within the expansion hierarchy.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-5'

      run do
        requests = load_tagged_requests(VALUE_SET_EXPAND_TAG)
        skip_if requests.empty?, 'No ValueSet/$expand requests were made.'

        value_sets = expanded_value_sets(requests)
        skip_if value_sets.empty?, 'No expanded ValueSet resources were returned.'

        value_sets.each do |value_set, request_index|
          value_set_expansion_errors(value_set).each do |error|
            add_request_message('error', error, request_index)
          end
        end

        error_message = "#{requests_with_errors_prefix}ValueSet expansions must use the current date " \
                        'and contain only active codes. See Messages for details.'
        assert_no_error_messages(error_message)
      end

      private

      def expanded_value_sets(requests)
        requests.filter_map.with_index do |request, request_index|
          resource = FHIR.from_contents(request.response_body)
          [resource, request_index] if resource.is_a?(FHIR::ValueSet) && resource.expansion.present?
        rescue JSON::ParserError, FHIR::ClientException
          nil
        end
      end
    end
  end
end
