# frozen_string_literal: true

require_relative '../questionnaire_operation_validation'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class AdaptiveQuestionnaireResponseContainedQuestionnaireTest < Inferno::Test
      include QuestionnaireOperationValidation
      include MultiRequestMessageHelper

      ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL =
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'

      id :dtr_v220_payer_adaptive_questionnaire_response_contained_questionnaire
      title 'Adaptive QuestionnaireResponses reference a contained Questionnaire'
      description %(
        This test verifies that each QuestionnaireResponse accompanying an adaptive
        Questionnaire in a `$questionnaire-package` response references a contained
        Questionnaire. The contained Questionnaire must be derived from the canonical
        URL of the adaptive Questionnaire being completed.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-25'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        adaptive_package_found = false

        requests.each_with_index do |request, request_index|
          resource = parse_fhir_request_entity(request.response_body, 'Response', request_index)
          next unless resource.present?

          extract_questionnaire_bundles(resource).each do |bundle|
            adaptive_questionnaire = bundle.entry.filter_map(&:resource).find do |entry_resource|
              adaptive_questionnaire?(entry_resource)
            end
            next unless adaptive_questionnaire.present?

            adaptive_package_found = true
            validate_questionnaire_response(bundle, adaptive_questionnaire, request_index)
          end
        end

        omit_if !adaptive_package_found, 'No adaptive Questionnaire packages were returned.'

        assert_no_error_messages(
          "#{requests_with_errors_prefix}Adaptive QuestionnaireResponses must reference a contained Questionnaire " \
          'derived from the adaptive Questionnaire canonical. See Messages for details.'
        )
      end

      private

      def adaptive_questionnaire?(resource)
        resource.is_a?(FHIR::Questionnaire) &&
          resource.extension.any? do |extension|
            extension.url == ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL &&
              (extension.valueBoolean || extension.valueUrl.present?)
          end
      end

      def validate_questionnaire_response(bundle, adaptive_questionnaire, request_index)
        questionnaire_response = bundle.entry.filter_map(&:resource).find do |entry_resource|
          entry_resource.is_a?(FHIR::QuestionnaireResponse)
        end

        unless questionnaire_response.present?
          add_request_message(
            'error',
            'Adaptive Questionnaire package contains no QuestionnaireResponse.',
            request_index
          )
          return
        end

        contained_questionnaire = referenced_contained_questionnaire(questionnaire_response, request_index)
        return unless contained_questionnaire.present?

        validate_derived_from(contained_questionnaire, adaptive_questionnaire, questionnaire_response, request_index)
      end

      def referenced_contained_questionnaire(questionnaire_response, request_index)
        reference = questionnaire_response.questionnaire
        unless reference&.start_with?('#')
          add_request_message(
            'error',
            'QuestionnaireResponse.questionnaire does not reference a contained Questionnaire.',
            request_index
          )
          return
        end

        contained_questionnaire = questionnaire_response.contained.find do |contained_resource|
          contained_resource.is_a?(FHIR::Questionnaire) && contained_resource.id == reference.delete_prefix('#')
        end
        unless contained_questionnaire.present?
          add_request_message(
            'error',
            "QuestionnaireResponse.questionnaire references `#{reference}`, " \
            'but no contained Questionnaire has that id.',
            request_index
          )
        end

        contained_questionnaire
      end

      def validate_derived_from(contained_questionnaire, adaptive_questionnaire, questionnaire_response, request_index)
        canonical = questionnaire_canonical(adaptive_questionnaire)
        return if canonical.present? && contained_questionnaire.derivedFrom.include?(canonical)

        add_request_message(
          'error',
          "Contained Questionnaire `#{questionnaire_response.questionnaire}` is not derived from `#{canonical}`.",
          request_index
        )
      end

      def questionnaire_canonical(questionnaire)
        return unless questionnaire.url.present?

        "#{questionnaire.url}#{"|#{questionnaire.version}" if questionnaire.version.present?}"
      end
    end
  end
end
