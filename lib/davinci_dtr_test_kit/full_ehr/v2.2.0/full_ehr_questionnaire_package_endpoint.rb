require 'udap_security_test_kit'
require_relative '../endpoints/mock_payer'
require_relative '../../cross_suite/fhirpath_utils'
require_relative '../fixture_loader'
require_relative '../../tags'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRV220QuestionnairePackageEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer
      include DaVinciDTRTestKit::FhirpathUtils

      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
          request.headers['authorization']&.delete_prefix('Bearer ')
        )
      end

      def tags
        [QUESTIONNAIRE_PACKAGE_TAG, test.config.options[:dtr_workflow_tag].presence].compact
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

      def response_body
        @response_body ||=
          if request_parameters.is_a?(FHIR::OperationOutcome)
            request_parameters
          elsif response_template.is_a?(FHIR::OperationOutcome)
            response_template
          elsif single_use_limit_exceeded?
            operation_outcome('error', 'business-rule',
                              '$questionnaire-package is configured to respond successfully only once.')
          else
            instantiate_template
          end
      end

      # ***********************************************************************
      # Template Instantiation
      # ***********************************************************************

      def instantiate_template
        replace_tokens(
          FHIR::Parameters.new(
            parameter: response_template.parameter.select { |param| include_parameter_entry?(param) }
          )
        )
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
      # Selection of parameter entries from the Template
      # ***********************************************************************

      def include_parameter_entry?(parameter)
        return false if parameter_entry_has_request_range_criteria?(parameter) &&
                        !request_meets_request_range_criteria?(parameter)
        return false if parameter_entry_has_inclusion_criteria?(parameter) &&
                        !request_meets_inclusion_criteria?(parameter)

        true
      end

      # ***********************************************************************
      # FHIRPath-based selection criteria
      # ***********************************************************************

      def parameter_entry_has_inclusion_criteria?(parameter)
        parameter.extension.any? { |ext| ext.url == 'urn:inferno:dtr:inclusion-criteria' }
      end

      def request_meets_inclusion_criteria?(parameter)
        criteria = parameter.extension.find do |ext|
          ext.url == 'urn:inferno:dtr:inclusion-criteria'
        end&.valueExpression&.expression
        return false unless criteria.present?

        fhirpath_result = execute_fhirpath(request_parameters.to_json, criteria)
        interpret_fhirpath_result_as_boolean(fhirpath_result)
      end

      # ***********************************************************************
      # request index-based selection criteria
      # ***********************************************************************

      def parameter_entry_has_request_range_criteria?(parameter)
        parameter.extension.any? { |ext| ext.url == 'urn:inferno:dtr:request-range' }
      end

      def request_meets_request_range_criteria?(parameter)
        criteria = parameter.extension.find { |ext| ext.url == 'urn:inferno:dtr:request-range' }&.valueString
        return false unless criteria.present?

        ranges_cover_value?(count_previous_requests + 1, criteria)
      end

      def single_use_limit_exceeded?
        test.config.options[:qp_single_use] && count_previous_requests >= 1
      end

      def count_previous_requests
        requests_repo = Inferno::Repositories::Requests.new
        previous_requests = requests_repo.requests_for_result(result.id)
        previous_requests.select { |req| req.url.include?('$questionnaire-package') && req.status == 200 }.count
      end

      def ranges_cover_value?(value, ranges_string)
        unless /\A(\d+(-\d+)?,)*\d+(-\d+)?\z/.match?(ranges_string)
          raise ArgumentError,
                "Invalid range string: #{ranges_string.inspect}"
        end

        ranges_string.split(',').any? do |part|
          if part.include?('-')
            a, b = part.split('-').map(&:to_i)
            raise ArgumentError, "Inverted range in: #{part.inspect}" if a > b

            (a..b).cover?(value)
          else
            part.to_i == value
          end
        end
      rescue ArgumentError => e
        raise Inferno::Exceptions::TestSuiteImplementationException.new('dtr response range criteria', e.message)
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
            parameters_template_from_input(test.config.options[:qp_response_template_input])
          else
            raise Inferno::Exceptions::TestSuiteImplementationException.new(
              'dtr qp response template',
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
            'dtr qp response template fixture',
            'Invalid $questionnaire-package response template fixture: ' \
            "Expected Parameters, got '#{fixture.resourceType}'."
          )
        end
        fixture
      end

      def parameters_template_from_input(input_name)
        value = JSON.parse(result.input_json)
          .find { |input| input['name'] == input_name }
          &.dig('value')

        unless value.present?
          return operation_outcome('error', 'invalid',
                                   "No response template provided by the user in input '#{input_name}'.")
        end

        parsed = parse_fhir_object(value, entity: "Input #{input_name}")
        if parsed.nil?
          return operation_outcome('error', 'invalid',
                                   "Input #{input_name} does not contain a valid FHIR Parameters resource.")
        end
        unless parsed.is_a?(FHIR::OperationOutcome) || parsed.is_a?(FHIR::Parameters)
          return operation_outcome('error', 'invalid',
                                   'Invalid input response template for $questionnaire-package: ' \
                                   "Expected Parameters, got '#{parsed.resourceType}'.")
        end

        parsed
      end
    end
  end
end
