# frozen_string_literal: true

require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../tags'
require_relative '../questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class InitialQuestionnaireResponseTest < Inferno::Test
      include MultiRequestMessageHelper
      include QuestionnaireOperationValidation

      CONTEXT_EXTENSION_URL = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/qr-context'

      id :dtr_v220_payer_initial_questionnaire_response
      title 'Questionnaire package contains initial QuestionnaireResponse context'
      description %(
        This test verifies that each QuestionnaireResponse returned in a
        `$questionnaire-package` Bundle is an initial response: it is in-progress.

        This test also verifies `qr-context` when the corresponding
        `$questionnaire-package` request supplies an `order` parameter. It
        verifies that a context reference is present in that scenario; it does
        not determine which input resource each QuestionnaireResponse is
        associated with or compare reference values.

        The Questionnaire Package Output Parameters profile validation separately
        verifies that every package Bundle contains exactly one DTR
        QuestionnaireResponse, including its required `subject` and `qr-coverage`
        elements.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-18'

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)
        questionnaire_responses_found = false

        requests.each_with_index do |request, request_index|
          package_bundles_from_request(request).each do |package_bundle|
            questionnaire_response = package_resources(package_bundle, FHIR::QuestionnaireResponse).first
            next unless questionnaire_response

            questionnaire_responses_found = true
            validate_initial_questionnaire_response(
              questionnaire_response,
              request_index,
              context_required: request_includes_context_resource?(request)
            )
          end
        end

        skip_if !questionnaire_responses_found,
                'No QuestionnaireResponse resources were returned; ' \
                'the response validation test verifies their presence.'

        message = "#{requests_with_errors_prefix}" \
                  'QuestionnaireResponses in package Bundles must be initial responses ' \
                  'with context when an order is supplied.'
        assert_no_error_messages("#{message} See Messages for details.")
      end

      private

      def validate_initial_questionnaire_response(questionnaire_response, request_index, context_required:)
        validate_initial_status(questionnaire_response, request_index)
        validate_context_extensions(questionnaire_response, request_index, context_required:)
      end

      def validate_initial_status(questionnaire_response, request_index)
        return if questionnaire_response.status == 'in-progress'

        add_request_message('error', 'QuestionnaireResponse.status must be `in-progress`.', request_index)
      end

      def validate_context_extensions(questionnaire_response, request_index, context_required:)
        return unless context_required

        validate_extension(questionnaire_response.extension || [], CONTEXT_EXTENSION_URL, 'qr-context', request_index)
      end

      def validate_extension(extensions, url, extension_name, request_index)
        references = extension_references(extensions, url)
        return unless references.empty?

        add_request_message(
          'error', "QuestionnaireResponse must include a #{extension_name} extension.", request_index
        )
      end

      def extension_references(extensions, url)
        extensions.filter_map do |extension|
          extension.valueReference if extension.url == url && extension.valueReference&.reference.present?
        end
      end

      def package_bundles_from_request(request)
        resource = FHIR.from_contents(request.response_body)
        return [] unless resource.is_a?(FHIR::Parameters)

        extract_questionnaire_bundles(resource)
      rescue JSON::ParserError
        []
      end

      def request_includes_context_resource?(request)
        parameters = request_parameters(request)
        parameter_resources(parameters, 'order').present?
      end

      def request_parameters(request)
        return unless request.request_body.present?

        resource = FHIR.from_contents(request.request_body)
        resource if resource.is_a?(FHIR::Parameters)
      rescue JSON::ParserError
        nil
      end

      def parameter_resources(parameters, name)
        return [] unless parameters

        parameters.parameter.filter_map { |parameter| parameter.resource if parameter.name == name }
      end

      def package_resources(package_bundle, resource_class)
        package_bundle.entry.filter_map do |entry|
          entry.resource if entry.resource.is_a?(resource_class)
        end
      end
    end
  end
end
