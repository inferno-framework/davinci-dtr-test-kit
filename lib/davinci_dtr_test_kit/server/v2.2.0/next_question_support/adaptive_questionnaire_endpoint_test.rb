# frozen_string_literal: true

require 'uri'

require_relative '../../../tags'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class AdaptiveQuestionnaireEndpointTest < Inferno::Test
      include QuestionnaireOperationValidation

      ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL =
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'

      id :dtr_v220_payer_adaptive_questionnaire_endpoint
      title 'Adaptive Questionnaire endpoints are payer sub-URLs accessible with the configured credentials'
      description %(
        This test verifies that every URL provided by a `questionnaireAdaptive`
        extension is a sub-URL of the payer FHIR base. It also verifies that the
        DTR client's `$next-question` request to that endpoint succeeds. The
        request is made by the same configured FHIR client used for the
        `$questionnaire-package` operation.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-24'

      input :url

      run do
        questionnaire_requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        successful_questionnaire_requests = questionnaire_requests.select do |request|
          request.status.to_s.start_with?('2')
        end
        skip_if successful_questionnaire_requests.blank?, 'No successful $questionnaire-package requests were made.'

        adaptive_urls = successful_questionnaire_requests.flat_map do |request|
          adaptive_questionnaire_urls(request)
        end.uniq
        skip_if adaptive_urls.blank?, 'No adaptive Questionnaire URLs were returned.'

        next_question_requests = load_tagged_requests(NEXT_TAG)
        adaptive_urls.each do |adaptive_url|
          unless payer_sub_url?(adaptive_url, url)
            add_message(
              'error',
              "Adaptive Questionnaire URL `#{adaptive_url}` is not a sub-URL of payer base `#{url}`."
            )
            next
          end

          expected_next_question_url = "#{adaptive_url.chomp('/')}/Questionnaire/$next-question"
          matching_request = next_question_requests.find { |request| request.url == expected_next_question_url }

          if matching_request.nil?
            add_message('error', "No $next-question request was made to adaptive Questionnaire URL `#{adaptive_url}`.")
          elsif !matching_request.status.to_s.start_with?('2')
            add_message(
              'error',
              "$next-question request to adaptive Questionnaire URL `#{adaptive_url}` did not succeed " \
              "(received HTTP #{matching_request.status})."
            )
          end
        end

        assert_no_error_messages(
          'Adaptive Questionnaire URLs must be payer sub-URLs and accessible with the configured credentials.'
        )
      end

      private

      def adaptive_questionnaire_urls(request)
        resource = FHIR::Json.from_json(request.response_body)
        extract_questionnaire_bundles(resource).flat_map do |bundle|
          adaptive_questionnaire_urls_from_bundle(bundle)
        end
      rescue JSON::ParserError, NoMethodError
        []
      end

      def adaptive_questionnaire_urls_from_bundle(bundle)
        extract_questionnaires_from_bundles([bundle]).filter_map do |questionnaire|
          adaptive_questionnaire_url(questionnaire)
        end
      end

      def adaptive_questionnaire_url(questionnaire)
        questionnaire.extension&.find do |extension|
          extension.url == ADAPTIVE_QUESTIONNAIRE_EXTENSION_URL && extension.valueUrl.present?
        end&.valueUrl
      end

      def payer_sub_url?(candidate, base)
        candidate_uri = URI.parse(candidate)
        base_uri = URI.parse(base)
        return false unless candidate_uri.absolute? &&
                            base_uri.absolute? &&
                            candidate_uri.scheme == base_uri.scheme &&
                            candidate_uri.host == base_uri.host &&
                            candidate_uri.port == base_uri.port

        base_path = base_uri.path.chomp('/')
        candidate_uri.path.start_with?("#{base_path}/")
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
