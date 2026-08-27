require_relative 'value_set_expansion_validation'
require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class SmallValueSetExpansionTest < Inferno::Test
      include ValueSetExpansionValidation
      include MultiRequestMessageHelper

      id :dtr_v220_payer_small_value_set_expansion
      title 'Verify small ValueSets are expanded'
      description %(
        This test verifies that all value sets with expansions under 40 entries will be expanded as of the
        current date and using expansion parameters as deemed appropriate by the payer.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-15'

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

          expansion = value_set.expansion

          next if expansion.total.present? && expansion.total >= 40

          unless value_set_expansion_current?(value_set)
            add_request_message('error', 'Small ValueSet expansion is not using current date', request_index)
            next
          end
        rescue JSON::ParserError, FHIR::ClientException
          add_request_message('error', 'ValueSet/$expand response is not a valid FHIR resource.', request_index)
        end

        error_message = "#{requests_with_errors_prefix}Small ValueSet expansions must use the current date"
        assert_no_error_messages(error_message)
      end
    end
  end
end
