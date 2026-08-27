require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRServerQuestionnairePackageContentsTest < Inferno::Test
      id :dtr_server_v220_payer_questionnaire_package_contents
      title 'Questionnaire package Bundles include the Questionnaire as the first entry'
      description %(
        The DTR Questionnaire Package operation requires each response Bundle to include
        the requested Questionnaire as its first entry.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-12'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?,
                'No $questionnaire-package requests were made in the Request Questionnaires test.'

        valid_questionnaire_package_found = false

        requests.each do |questionnaire_package_exchange|
          JSON.parse(questionnaire_package_exchange.response_body)

          questionnaire_package_parameters = FHIR.from_contents(
            questionnaire_package_exchange.response_body
          )

          next unless questionnaire_package_parameters&.resourceType == 'Parameters'

          package_bundles = questionnaire_package_parameters.parameter.filter_map do |parameter|
            parameter.resource if parameter.name == 'packagebundle'
          end

          next if package_bundles.blank?

          valid_questionnaire_package_found = true

          package_bundles.each do |package_bundle|
            unless package_bundle.resourceType == 'Bundle'
              add_message(
                'error',
                'Unexpected resource type: expected Bundle, but received ' \
                "#{package_bundle.resourceType}"
              )
              next
            end

            first_entry = package_bundle.entry.first

            unless first_entry.present?
              add_message(
                'error',
                'Each questionnaire-package Bundle must contain at least one entry.'
              )
              next
            end

            unless first_entry.resource.present?
              add_message(
                'error',
                'The first entry in each questionnaire-package Bundle must contain a resource.'
              )
              next
            end

            next if first_entry.resource.resourceType == 'Questionnaire'

            add_message(
              'error',
              'Unexpected resource type: expected Questionnaire, but received ' \
              "#{first_entry.resource.resourceType}"
            )
          end
        rescue JSON::ParserError
          next
        end

        skip_if !valid_questionnaire_package_found,
                'No valid questionnaire-package response Bundles were found.'

        assert_no_error_messages(
          'Not all questionnaire-package Bundles included the Questionnaire as the first entry.'
        )
      end
    end
  end
end
