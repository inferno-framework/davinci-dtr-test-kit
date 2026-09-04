require_relative '../../../tags'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class DTRNoCustomExtensionTest < Inferno::Test
      US_CORE_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-direct',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
        'http://hl7.org/fhir/us/core/StructureDefinition/uscdi-requirement',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-extension-questionnaire-uri',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-genderIdentity',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-jurisdiction',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-sex',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-tribal-affiliation',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication-adherence',
        'http://hl7.org/fhir/StructureDefinition/condition-assertedDate'
      ].freeze

      HREX_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-hrex/StructureDefinition/extension-CoverageDavinciWellknownLocation'
      ].freeze

      CRD_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-coverage-information',
        'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-billing-options',
        'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-request-category',
        'http://hl7.org/fhir/StructureDefinition/codeOptions',
        'http://hl7.org/fhir/StructureDefinition/alternate-reference',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-CommunicationRequest.payload.content',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.requestedPeriod',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.requestedPerformer',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.performer',
        'http://hl7.org/fhir/StructureDefinition/request-doNotPerform',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.input.value',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.output.value',
        'http://hl7.org/fhir/5.0/StructureDefinition/extension-Task.statusReason'
      ].freeze

      DTR_EXTENSION_URLS = [
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/activeRole',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/alternativeExpression',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/containedReference',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/intendedUse',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-context',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/estimated-completion-time',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/questionnaireAudience',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-coverage',
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/request-specific'
      ].freeze

      SDC_EXTENSION_URLS = [
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-answerExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-answerOptionsToggleExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assemble-expectation',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembleContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembleDefinitionRoot',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-assembledFrom',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-choiceColumn',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-collapsible',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-columnCount',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-contextExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtract',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-definitionExtractValue',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-endpoint',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-entryMode',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-extractAllocateId',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-isSubject',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemAnswerMedia',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemExtractionContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemMedia',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemPopulationContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-keyboard',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-launchContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-lookupQuestionnaire',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-maxQuantity',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-minQuantity',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observation-extract-category',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationExtract',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationExtractEntry',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-observationLinkPeriod',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-openLabel',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-optionalDisplay',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-performerType',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-preferredTerminologyServer',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-shortText',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-sourceQueries',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-sourceStructureMap',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-subQuestionnaire',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-targetStructureMap',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtract',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractBundle',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractContext',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-templateExtractValue',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-unitOpen',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-unitSupplementalSystem',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-width',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-isSubject',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-rendering-criticalExtension',
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-servicerequest-questionnaire'
      ].freeze

      VALID_EXTENSION_URLS = (US_CORE_EXTENSION_URLS + HREX_EXTENSION_URLS \
        + DTR_EXTENSION_URLS + SDC_EXTENSION_URLS).freeze

      id :dtr_server_v220_no_custom_extension_test
      title 'Server processes $questionnaire-package without custom extensions'
      description %(
        This test verifies that the DTR server can successfully process a
        $questionnaire-package request without depending on extensions outside
        those defined by DTR, HRex, or US Core.

        Successful requests containing additional extensions are permitted.
        The test passes when at least one successful request is observed that
        does not depend on such extensions.
      )

      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@conf-8'

      run do
        requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.blank?, 'No requests were made in a previous test as expected.'

        successful_requests = requests.select { |request| request.status == 200 }
        skip_if successful_requests.empty?, 'All service requests were unsuccessful.'

        resources = successful_requests.filter_map { |request| resource_from_request(request) }
        skip_if resources.empty?, 'No FHIR resources were found in successful $questionnaire-package requests.'

        request_with_no_custom_extensions = resources.any? do |resource|
          no_custom_extensions?(resource)
        end

        pass_if request_with_no_custom_extensions

        custom_extensions_string = resources
          .flat_map { |resource| custom_extensions(resource) }
          .uniq
          .map { |extension| "\n- `#{extension}`" }
          .join

        skip 'No requests were made without custom extensions. The following custom extensions were found: ' \
             "#{custom_extensions_string}"
      end

      def resource_from_request(request)
        FHIR.from_contents(request.request_body)
      rescue JSON::ParserError
        nil
      end

      def no_custom_extensions?(bundle)
        bundle.each_element do |value, _metadata, path|
          next unless value.is_a?(FHIR::Extension)

          next if path.to_s.scan('extension').length > 1

          return false unless VALID_EXTENSION_URLS.include?(value.url.to_s)
        end

        true
      end

      def custom_extensions(bundle)
        [].tap do |custom_extensions|
          bundle.each_element do |value, _metadata, path|
            next unless value.is_a?(FHIR::Extension)

            next if path.to_s.scan('extension').length > 1

            custom_extensions << value.url.to_s unless VALID_EXTENSION_URLS.include?(value.url.to_s)
          end
        end
      end
    end
  end
end
