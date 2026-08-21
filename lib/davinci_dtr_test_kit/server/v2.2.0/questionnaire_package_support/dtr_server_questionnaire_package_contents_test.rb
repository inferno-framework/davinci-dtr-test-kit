require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRServerQuestionnairePackageContentsTest < Inferno::Test
      id :dtr_server_v220_payer_questionnaire_package_contents
      title 'Questionnaire package response includes the Questionnaire and referenced Libraries'
      description %(
        The DTR Questionnaire Package operation requires the response Bundle to include
        the requested Questionnaire as its first entry. The Bundle must also include external
        Libraries referenced by the Questionnaire and Libraries referenced through
        `relatedArtifact` dependencies.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-12'

      CQF_LIBRARY_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/cqf-library'.freeze

      def cqf_library_canonicals(questionnaire)
        questionnaire.extension.filter_map do |extension|
          extension.valueCanonical if extension.url == CQF_LIBRARY_EXTENSION_URL
        end
      end

      def library_for_canonical(package_bundle, canonical)
        library_url, library_version = canonical.split('|', 2)

        package_bundle.entry.map(&:resource).find do |bundle_resource|
          bundle_resource.resourceType == 'Library' &&
            bundle_resource.url == library_url &&
            (library_version.blank? || bundle_resource.version == library_version)
        end
      end

      def depends_on_canonicals(library)
        library.relatedArtifact.filter_map do |related_artifact|
          related_artifact.resource if related_artifact.type == 'depends-on'
        end
      end

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?,
                'No $questionnaire-package requests were made in the Request Questionnaires test.'

        previous_questionnaire_package_exchange = requests.first

        assert_valid_json(previous_questionnaire_package_exchange.response_body)

        questionnaire_package_parameters = FHIR.from_contents(
          previous_questionnaire_package_exchange.response_body
        )

        assert_resource_type(:parameters, resource: questionnaire_package_parameters)
        assert_valid_resource(resource: questionnaire_package_parameters)

        package_bundles = questionnaire_package_parameters.parameter.filter_map do |parameter|
          parameter.resource if parameter.name == 'packagebundle'
        end

        assert package_bundles.present?,
               'The questionnaire-package response does not contain a `packagebundle` parameter.'

        package_bundles.each do |package_bundle|
          assert_resource_type(:bundle, resource: package_bundle)

          first_entry = package_bundle.entry.first

          assert first_entry.present?,
                 'Each questionnaire-package Bundle must contain at least one entry.'

          assert first_entry.resource.present?,
                 'The first entry in each questionnaire-package Bundle must contain a resource.'

          assert_resource_type(:questionnaire, resource: first_entry.resource)

          library_canonicals = cqf_library_canonicals(first_entry.resource)
          checked_library_canonicals = []

          until library_canonicals.empty?
            library_canonical = library_canonicals.shift

            next if checked_library_canonicals.include?(library_canonical)

            checked_library_canonicals << library_canonical

            library = library_for_canonical(package_bundle, library_canonical)

            assert library.present?,
                   "The questionnaire-package Bundle is missing Library `#{library_canonical}`."

            library_canonicals.concat(depends_on_canonicals(library))
          end
        end
      end
    end
  end
end
