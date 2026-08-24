# frozen_string_literal: true

require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../tags'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireResponseQuestionnaireCanonicalTest < Inferno::Test
      include MultiRequestMessageHelper
      include QuestionnaireOperationValidation

      id :dtr_v220_payer_questionnaire_response_questionnaire_canonical
      title 'QuestionnaireResponse references the package Questionnaire canonical'
      description %(
        This test verifies that each QuestionnaireResponse returned in a
        `$questionnaire-package` package Bundle references the canonical of a
        Questionnaire returned in that same package Bundle.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-122'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        questionnaire_responses_found = false

        requests.each_with_index do |request, request_index|
          package_bundles_from_request(request).each do |package_bundle|
            questionnaire_response = package_resources(package_bundle, FHIR::QuestionnaireResponse).first
            next unless questionnaire_response

            questionnaire_responses_found = true
            questionnaire = package_resources(package_bundle, FHIR::Questionnaire).first
            questionnaire_canonical = canonical(questionnaire)
            next if questionnaire_response.questionnaire == questionnaire_canonical

            add_request_message(
              'error',
              "QuestionnaireResponse.questionnaire `#{questionnaire_response.questionnaire}` does not " \
              "match a Questionnaire canonical in its package Bundle (#{questionnaire_canonical}).",
              request_index
            )
          end
        end

        skip_if !questionnaire_responses_found, 'No QuestionnaireResponse resources were returned.'

        message = "#{requests_with_errors_prefix}" \
                  'QuestionnaireResponse.questionnaire must match a Questionnaire canonical in its package Bundle.'
        assert_no_error_messages("#{message} See Messages for details.")
      end

      private

      def package_bundles_from_request(request)
        resource = FHIR.from_contents(request.response_body)
        return [] unless resource.is_a?(FHIR::Parameters)

        extract_questionnaire_bundles(resource)
      rescue JSON::ParserError, FHIR::ClientException
        []
      end

      def package_resources(package_bundle, resource_class)
        package_bundle.entry.filter_map do |entry|
          entry.resource if entry.resource.is_a?(resource_class)
        end
      end

      def canonical(questionnaire)
        return if questionnaire.blank? || questionnaire.url.blank?

        "#{questionnaire.url}#{"|#{questionnaire.version}" if questionnaire.version.present?}"
      end
    end
  end
end
