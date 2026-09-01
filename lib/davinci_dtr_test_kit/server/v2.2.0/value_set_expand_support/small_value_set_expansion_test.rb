require_relative '../../../tags'
require_relative '../questionnaire_operation_validation'
require_relative 'value_set_expansion_validation'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class SmallValueSetExpansionTest < Inferno::Test
      include QuestionnaireOperationValidation
      include ValueSetExpansionValidation
      include MultiRequestMessageHelper

      id :dtr_v220_payer_small_value_set_expansion
      title 'Verify small ValueSets are expanded'
      description %(
        This test verifies that ValueSets with fewer than 40 entries returned by
        $questionnaire-package are expanded.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-15'

      run do
        requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.empty?, 'No $questionnaire-package requests were made.'

        expansion_sizes = expansion_sizes_by_url

        requests.each_with_index do |request, request_index|
          next unless [200, 201].include? request.status

          resource = FHIR.from_contents(request.response_body)

          extract_questionnaire_bundles(resource).each do |bundle|
            bundle.entry.filter_map(&:resource).grep(FHIR::ValueSet).each do |value_set|
              url = value_set.url
              expansion_size = expansion_sizes[url]

              if value_set_expanded?(value_set)
                if value_set.expansion.present? && !value_set_expansion_current?(value_set)
                  add_request_message('error', expansion_timestamp_error(value_set, Date.current), request_index)
                end
                next
              end

              next if expansion_size.nil? || expansion_size >= 40

              next if value_set_expanded?(value_set)

              add_request_message(
                'error',
                "ValueSet `#{url}` has #{expansion_size} codes and is not expanded in the " \
                '$questionnaire-package response.',
                request_index
              )
              next
            end
          end
        rescue JSON::ParserError, FHIR::ClientException
          add_request_message('error', '$questionnaire-package response is not a valid FHIR resource.', request_index)
        end

        assert_no_error_messages(
          "#{requests_with_errors_prefix}Small ValueSets returned by $questionnaire-package must be expanded."
        )
      end

      def expansion_sizes_by_url
        load_tagged_requests(VALUE_SET_EXPAND_TAG).filter_map do |request|
          url = value_set_url_from_expand_request(request)
          next if url.blank?

          expanded_value_set = FHIR.from_contents(request.response_body)

          next unless expanded_value_set.is_a?(FHIR::ValueSet) &&
                      expanded_value_set.expansion.present?

          [url, expansion_entry_count(expanded_value_set.expansion.contains)]
        rescue JSON::ParserError, FHIR::ClientException
          nil
        end.to_h
      end

      def value_set_expanded?(value_set)
        value_set_expansion_contains_codes?(value_set) ||
          value_set_compose_contains_only_codes?(value_set)
      end

      def value_set_expansion_contains_codes?(value_set)
        value_set.expansion&.contains.present?
      end

      def value_set_compose_contains_only_codes?(value_set)
        compose = value_set.compose
        return false if compose.blank? || compose.exclude.present?

        compose.include.present? &&
          compose.include.all? do |include|
            include.concept.present? &&
              include.filter.blank? &&
              include.valueSet.blank?
          end
      end

      def expansion_entry_count(contains)
        return 0 if contains.blank?

        contains.sum do |entry|
          1 + expansion_entry_count(entry.contains)
        end
      end

      def value_set_url_from_expand_request(request)
        parameters = FHIR.from_contents(request.request_body)

        url = parameters.parameter
          .find { |parameter| parameter.name == 'url' }
          &.valueUri

        url&.split('|', 2)&.first
      end
    end
  end
end
