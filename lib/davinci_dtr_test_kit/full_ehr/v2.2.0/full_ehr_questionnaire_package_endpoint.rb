require 'udap_security_test_kit'
require_relative '../endpoints/mock_payer'
require_relative '../../cross_suite/fhirpath_utils'
require_relative '../../cross_suite/response_selection_utils'
require_relative '../fixture_loader'
require_relative '../../tags'
require_relative 'full_ehr_supporting_resources'
require_relative 'next_question_template_questionnaires'
require_relative 'package_questionnaire_templates'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRV220QuestionnairePackageEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer
      include DaVinciDTRTestKit::FhirpathUtils
      include DaVinciDTRTestKit::ResponseSelectionUtils
      include FullEHRV220SupportingResources
      include DaVinciDTRTestKit::NextQuestionTemplateQuestionnaires
      include DaVinciDTRTestKit::PackageQuestionnaireTemplates

      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
          request.headers['authorization']&.delete_prefix('Bearer ')
        )
      end

      def tags
        tags = [QUESTIONNAIRE_PACKAGE_TAG]
        tags << test.config.options[:dtr_workflow_tag] if test.config.options[:dtr_workflow_tag].present?
        unless test.config.options[:dtr_exclude_from_questionnaire_must_support]
          tags << CLIENT_QUESTIONNAIRE_MUST_SUPPORT
        end

        tags
      end

      def make_response
        response.headers['Access-Control-Allow-Origin'] = '*'
        return if response.status == 401 # response set in update_result (expired token handling there)

        response.format = 'application/fhir+json'
        response.body = response_body.to_json
        response.status = if response_body.is_a?(FHIR::OperationOutcome)
                            400
                          else
                            200
                          end
      rescue StandardError => e
        Inferno::Application['logger'].error("Error responding to $questionnaire-package:\n#{e.full_message}")
        response.body =
          operation_outcome(
            'fatal',
            'processing',
            e.message
          ).to_json
        response.status = 500
      end

      def update_result
        return unless UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)

        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
      end

      private

      # ***********************************************************************
      # Response Body
      # ***********************************************************************

      def response_body
        @response_body ||= build_response_body
      end

      def build_response_body
        if !request_parameters.is_a?(FHIR::Parameters)
          operation_outcome('error', 'invalid', 'Request body must be a FHIR Parameters resource.')
        elsif response_template.is_a?(FHIR::OperationOutcome)
          response_template
        elsif single_use_limit_exceeded?
          operation_outcome('error', 'business-rule',
                            '$questionnaire-package is configured to respond successfully only once.')
        else
          instantiate_template
        end
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end

      def single_use_limit_exceeded?
        test.config.options[:qp_single_use] &&
          count_previous_successful_requests('$questionnaire-package') >= 1
      end

      # ***********************************************************************
      # Template Instantiation
      # ***********************************************************************

      def instantiate_template
        # Work on a copy so that expanding placeholders doesn't change the (cached) template.
        selected = FHIR.from_contents(select_package_parameters.to_json)
        expand_template_placeholders(selected)
        result = replace_tokens(selected)
        return result unless result.is_a?(FHIR::Parameters)

        add_supporting_resources_to_package_bundles(result)
        clean_up_instantiation(result)
        result
      rescue FhirpathServiceError, MissingTemplateError => e
        raise_if_fixture_template_error('dtr $questionnaire-package response template', e)

        operation_outcome('error', 'invalid', e.message)
      end

      # Errors in developer-provided fixtures are bugs in the test kit rather than tester mistakes.
      def raise_if_fixture_template_error(source, error)
        return unless template_from_fixture?
        raise error if error.is_a?(FhirpathServiceError)

        raise Inferno::Exceptions::TestSuiteImplementationException.new(source, error.message)
      end

      def select_package_parameters
        FHIR::Parameters.new(
          parameter: response_template.parameter.select do |param|
            include_entity?(param, request_parameters, '$questionnaire-package')
          end
        )
      end

      # Adds the configured Libraries and ValueSets referenced by each package bundle's
      # Questionnaires that the bundle doesn't already include.
      def add_supporting_resources_to_package_bundles(parameters)
        package_bundles(parameters).each do |bundle|
          canonicals = package_questionnaires(bundle).flat_map { |questionnaire| referenced_canonicals(questionnaire) }
          resolve_supporting_resources(canonicals, exclude: bundle.entry.map(&:resource)).each do |resource|
            bundle.entry << FHIR::Bundle::Entry.new(resource:)
          end
        end
      end

      def clean_up_instantiation(instantiated_parameters)
        instantiated_parameters.parameter.each do |param|
          strip_inferno_extensions(param)
        end
        package_bundles(instantiated_parameters).flat_map { |bundle| package_questionnaires(bundle) }
          .each do |questionnaire|
            strip_inferno_extensions(questionnaire)
            all_questionnaire_items(questionnaire.item).each { |item| strip_inferno_extensions(item) }
          end
      end

      # ***********************************************************************
      # Replace {{fhirpath}} tokens in template
      # ***********************************************************************

      def replace_tokens(parameters_resource)
        instantiated_json = replace_tokens_in_string(parameters_resource.to_json, request_parameters)
        FHIR.from_contents(instantiated_json)
      rescue JSON::ParserError => e
        if template_from_fixture?
          raise Inferno::Exceptions::TestSuiteImplementationException.new('dtr response template tokens', e.message)
        end

        operation_outcome('error', 'invalid', e.message)
      end

      # ***********************************************************************
      # Request Contents
      # ***********************************************************************

      def request_parameters
        @request_parameters ||= parse_fhir_object(request.body.string)
      end

      # ***********************************************************************
      # Response Template
      # ***********************************************************************

      def response_template
        @response_template ||=
          if template_from_fixture?
            parameters_template_from_fixture
          elsif template_from_input?
            parameters_template_from_input
          else
            raise Inferno::Exceptions::TestSuiteImplementationException.new(
              'dtr $questionnaire-package response template',
              'No response template source indicated by the test implementer, please file a bug report.'
            )
          end
      end

      def template_from_fixture?
        test.config.options[:qp_response_template_fixture].present?
      end

      def template_from_input?
        !template_from_fixture? && test.config.options[:qp_response_template_input].present?
      end

      # The $next-question template Questionnaires, used to expand package Questionnaire placeholders.
      def next_question_templates
        @next_question_templates ||= load_next_question_templates
      end

      def load_next_question_templates
        fixture_path = test.config.options[:nq_questionnaire_template_fixture]
        input_name = test.config.options[:nq_questionnaire_template_input]
        if fixture_path.present?
          [FixtureLoader.instance[fixture_path]].grep(FHIR::Questionnaire)
        elsif input_name.present?
          value = JSON.parse(result.input_json).find { |input| input['name'] == input_name }&.dig('value')
          value.present? ? questionnaires_from_template_value(value) : []
        else
          []
        end
      rescue JSON::ParserError
        []
      end

      def parameters_template_from_fixture
        fixture = FixtureLoader.instance[test.config.options[:qp_response_template_fixture]]
        unless fixture.is_a?(FHIR::Parameters)
          raise Inferno::Exceptions::TestSuiteImplementationException.new(
            'dtr $questionnaire-package response template fixture',
            'Invalid $questionnaire-package response template fixture: ' \
            "Expected Parameters, got '#{fixture.resourceType}'."
          )
        end
        fixture
      end

      def parameters_template_from_input
        input_name = test.config.options[:qp_response_template_input]
        value = JSON.parse(result.input_json)
          .find { |input| input['name'] == input_name }
          &.dig('value')

        title = input_title(input_name)
        unless value.present?
          return operation_outcome('error', 'invalid',
                                   "No response template provided by the user in input '#{title}'.")
        end

        parse_parameters_input_template(value, title)
      end

      def parse_parameters_input_template(value, title)
        parsed = parse_fhir_object(value, entity: "Input #{title}")
        unless parsed.is_a?(FHIR::Parameters)
          return operation_outcome('error', 'invalid',
                                   'Invalid input response template for $questionnaire-package: ' \
                                   "Expected Parameters, got '#{parsed.resourceType}'.")
        end
        parsed
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end

      # test.config.options input references are stored as input names; testers only see the
      # input's title in the Inferno UI, so client-facing messages should use that instead.
      def input_title(input_name)
        test.config.input(input_name.to_sym)&.title || input_name
      end
    end
  end
end
