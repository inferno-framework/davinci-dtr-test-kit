require_relative '../questionnaire_response_reference_validation'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../tags'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireReferencesVersionTest < Inferno::Test
      include QuestionnaireResponseReferenceValidation
      include MultiRequestMessageHelper
      include QuestionnaireOperationValidation

      id :dtr_v220_payer_questionnaire_references_version_specific
      title 'Validate version-specific references'
      description %(
        This test validates that references to Questionnaires, Libraries, and ValueSets within a Bundle
        is version specific.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-16'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?, 'No $questionnaire-package requests were made'

        successful_requests = requests.each_with_index.filter_map do |request, request_index|
          [request, request_index] if [200, 201].include?(request.status)
        end

        skip_if successful_requests.blank?, 'No successful $questionnaire-package requests were made'

        successful_requests.each do |request, request_index|
          resource = FHIR.from_contents(request.response_body)
          next if resource.nil?

          extract_questionnaire_bundles(resource).each_with_index do |bundle, bundle_index|
            extract_questionnaires_from_bundles([bundle]).each do |questionnaire|
              add_message('error', 'Unversioned Questionnaire reference') unless questionnaire.version.present?

              referenced_value_set(questionnaire.item).each do |canonical|
                next if check_version_reference?(canonical)

                add_message(
                  'error',
                  "Request #{request_index}, Bundle #{bundle_index}: Unversioned ValueSet reference: `#{canonical}`"
                )
              end

              referenced_library_canonicals(questionnaire).each do |canonical|
                next if check_version_reference?(canonical)

                add_message(
                  'error',
                  "Request #{request_index}, Bundle #{bundle_index}: Unversioned Library reference: `#{canonical}`"
                )
              end
            end
          end
        end

        message = "#{requests_with_errors_prefix}References to Questionnaires, Libraries, and ValueSets " \
                  'within questionnaire package Bundles must be version-specific. '

        assert_no_error_messages("#{message}See Messages for details.")
      end

      def referenced_value_set(items)
        items.flat_map do |item|
          references = []

          references << item.answerValueSet if item.answerValueSet.present?

          references + referenced_value_set(item.item)
        end
      end

      def check_version_reference?(reference)
        _url, separator, version = reference.to_s.partition('|')

        separator.present? && version.present?
      end
    end
  end
end
