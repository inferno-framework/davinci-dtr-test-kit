require 'udap_security_test_kit'
require_relative '../endpoints/mock_payer'
require_relative '../../cross_suite/fhirpath_utils'
require_relative '../../cross_suite/response_selection_utils'
require_relative '../fixture_loader'
require_relative '../../tags'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRV220QuestionnairePackageEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer
      include DaVinciDTRTestKit::FhirpathUtils
      include DaVinciDTRTestKit::ResponseSelectionUtils

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
        result = replace_tokens(
          FHIR::Parameters.new(
            parameter: response_template.parameter.select do |param|
              include_entity?(param, request_parameters, '$questionnaire-package')
            end
          )
        )
        result.parameter.each { |param| strip_inferno_extensions(param) } if result.is_a?(FHIR::Parameters)
        result
      rescue FhirpathServiceError => e
        raise if template_from_fixture?

        operation_outcome('error', 'invalid', e.message)
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

        unless value.present?
          return operation_outcome('error', 'invalid',
                                   "No response template provided by the user in input '#{input_name}'.")
        end

        parse_parameters_input_template(value, input_name)
      end

      def parse_parameters_input_template(value, input_name)
        parsed = parse_fhir_object(value, entity: "Input #{input_name}")
        unless parsed.is_a?(FHIR::Parameters)
          return operation_outcome('error', 'invalid',
                                   'Invalid input response template for $questionnaire-package: ' \
                                   "Expected Parameters, got '#{parsed.resourceType}'.")
        end
        parsed
      rescue MockPayer::ParseError => e
        operation_outcome('error', 'invalid', e.message)
      end
    end
  end
end
