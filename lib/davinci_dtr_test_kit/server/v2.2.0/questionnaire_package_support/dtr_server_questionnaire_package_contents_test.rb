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

        package_bundle_errors = []

        requests.each do |questionnaire_package_exchange|
          assert_valid_json(questionnaire_package_exchange.response_body)

          questionnaire_package_parameters = FHIR.from_contents(
            questionnaire_package_exchange.response_body
          )

          assert_resource_type(:parameters, resource: questionnaire_package_parameters)
          assert_valid_resource(resource: questionnaire_package_parameters)

          package_bundles = questionnaire_package_parameters.parameter.filter_map do |parameter|
            parameter.resource if parameter.name == 'packagebundle'
          end

          assert package_bundles.present?,
                 'The questionnaire-package response does not contain a `packagebundle` parameter.'

          package_bundles.each do |package_bundle|
            unless package_bundle.resourceType == 'Bundle'
              package_bundle_errors << 'Unexpected resource type: expected Bundle, but received ' \
                                       "#{package_bundle.resourceType}"
              next
            end

            first_entry = package_bundle.entry.first

            unless first_entry.present?
              package_bundle_errors << 'Each questionnaire-package Bundle must contain at least one entry.'
              next
            end

            unless first_entry.resource.present?
              package_bundle_errors << 'The first entry in each questionnaire-package Bundle must contain a resource.'
              next
            end

            next if first_entry.resource.resourceType == 'Questionnaire'

            package_bundle_errors <<
              'Unexpected resource type: expected Questionnaire, but received ' \
              "#{first_entry.resource.resourceType}"
          end
        end

        assert package_bundle_errors.empty?, package_bundle_errors.join("\n")
      end
    end
  end
end
