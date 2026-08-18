require_relative '../../../tags'
require_relative '../../validation_test'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class ValueSetValidationTest < Inferno::Test
      include DaVinciDTRTestKit::ValidationTest
      include QuestionnaireOperationValidation

      id :dtr_v220_payer_value_set_validation
      title 'Validate questionnaire-package response Bundle includes all external ValueSet instances'
      description %(
        This test validates the response to the $questionnaire-package includes all external ValueSet
        instances referenced by the Questionnaire.

        It verifies that the Bundle includes all ValueSet instances referenced by the Questionnaire.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-14'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?, 'No $questionnaire-package requests were made'

        successful_requests = requests.select { |request| [200, 201].include? request.response.status }

        skip_if successful_requests.blank?, 'No successful $questionnaire-package requests were made'

        external_value_set_referenced = false

        successful_requests.each do |request|
          resource = FHIR.from_contents(request.response_body)

          extract_questionnaire_bundles(resource).each do |bundle|
            bundle_value_set_urls = bundle.entry.filter_map do |entry|
              next unless entry&.resource.is_a?(FHIR::ValueSet)

              "#{entry.resource.url}|#{entry.resource.version}"
            end

            external_value_set_urls = extract_questionnaires_from_bundles([bundle]).flat_map do |questionnaire|
              value_set_urls_from_items(questionnaire.item)
            end

            next if external_value_set_urls.empty?

            external_value_set_referenced = true

            missing_value_set_urls = external_value_set_urls.uniq - bundle_value_set_urls.uniq

            assert missing_value_set_urls.empty?,
                   "Bundle is missing ValueSet instances: #{missing_value_set_urls.join(', ')}"
          end
        end

        omit_if !external_value_set_referenced, 'No external ValueSet referenced'
      end

      def value_set_urls_from_items(items)
        items.flat_map do |item|
          urls = []
          add_value_set_url(urls, item.answerValueSet)
          urls + value_set_urls_from_items(item.item)
        end
      end

      def add_value_set_url(urls, reference)
        reference = reference.to_s
        return if reference.blank? || reference.start_with?('#')

        urls << reference
      end
    end
  end
end
