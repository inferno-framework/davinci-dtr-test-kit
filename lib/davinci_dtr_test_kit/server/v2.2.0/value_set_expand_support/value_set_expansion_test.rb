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

        requests.each_with_index do |request, request_index|
          value_set = FHIR.from_contents(request.response_body)
          unless value_set.is_a?(FHIR::ValueSet)
            add_request_message('error', 'ValueSet/$expand response is not a ValueSet resource.', request_index)
            next
          end

          unless value_set.expansion.present?
            add_request_message('error', 'ValueSet response does not contain an expansion.', request_index)
            next
          end

          value_set_expansion_errors(value_set).each do |error|
            add_request_message('error', error, request_index)
          end
        rescue JSON::ParserError, FHIR::ClientException
          add_request_message('error', 'ValueSet/$expand response is not a valid FHIR resource.', request_index)
        end

        error_message = "#{requests_with_errors_prefix}ValueSet expansions must use the current date " \
                        'and contain only active codes. See Messages for details.'
        assert_no_error_messages(error_message)
      end
    end
  end
end
