require 'udap_security_test_kit'
require_relative '../endpoints/mock_payer'
require_relative '../../tags'
require_relative '../../cross_suite/inferno_control_extensions'
require_relative 'full_ehr_supporting_resources'

module DaVinciDTRTestKit
  module MockPayer
    # Simulates the payer's ValueSet/$expand operation using the ValueSets from the Bundle
    # configured by the value_set_bundle_* options (see DTRFullEHRV220AbstractAdaptive). The
    # requested ValueSet is identified by the `url` (and optional `valueSetVersion`) parameter,
    # or by the url and version of a `valueSet` parameter, and must have an expansion in the
    # Bundle. The response is a copy of that ValueSet with the expansion timestamp set to the
    # current time.
    class FullEHRV220ValueSetExpandEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer
      include FullEHRV220SupportingResources

      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
          request.headers['authorization']&.delete_prefix('Bearer ')
        )
      end

      def tags
        tags = [CLIENT_VALUE_SET_EXPAND_TAG]
        tags << test.config.options[:dtr_workflow_tag] if test.config.options[:dtr_workflow_tag].present?
        tags
      end

      def make_response
        response.headers['Access-Control-Allow-Origin'] = '*'
        return if response.status == 401 # response set in update_result (expired token handling there)

        response.format = 'application/fhir+json'
        status, body = expand_response
        response.body = body.to_json
        response.status = status
      rescue StandardError => e
        Inferno::Application['logger'].error("Error responding to ValueSet/$expand:\n#{e.full_message}")
        response.body = operation_outcome('fatal', 'processing', e.message).to_json
        response.status = 500
      end

      def update_result
        return unless UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)

        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
      end

      private

      # ***********************************************************************
      # Response
      # ***********************************************************************

      # Returns the HTTP status and the resource to respond with.
      def expand_response
        canonical = requested_canonical
        if canonical.blank?
          return [400, operation_outcome('error', 'required',
                                         'ValueSet/$expand requests must identify the ValueSet using the `url` ' \
                                         'parameter or a `valueSet` parameter with a url.')]
        end

        value_set = find_by_canonical(supporting_resources.grep(FHIR::ValueSet), canonical)
        if value_set.nil?
          return [404, operation_outcome('error', 'not-found',
                                         "ValueSet #{canonical} is not available from Inferno during this test.")]
        end
        unless value_set.expansion.present?
          return [400, operation_outcome('error', 'not-supported',
                                         "Inferno does not have an expansion for ValueSet #{canonical}.")]
        end

        [200, expanded_value_set(value_set)]
      rescue MockPayer::ParseError => e
        [400, operation_outcome('error', 'invalid', e.message)]
      end

      # A copy of the configured ValueSet, so that the configured Bundle is not changed.
      def expanded_value_set(value_set)
        copy = FHIR::ValueSet.new(value_set.to_hash)
        copy.extension.reject! { |extension| InfernoControlExtensions::ALL_URLS.include?(extension.url) }
        copy.expansion.timestamp = Time.now.utc.iso8601
        copy
      end

      # ***********************************************************************
      # Request Contents
      # ***********************************************************************

      # The requested ValueSet as a canonical (`url` or `url|version`). Parameters in a POST body
      # take precedence over query parameters.
      def requested_canonical
        url = parameter_value('url', :valueUri) || request.params[:url]
        version = parameter_value('valueSetVersion', :valueString) || request.params[:valueSetVersion]
        if url.blank?
          inline_value_set = parameter_value('valueSet', :resource)
          url = inline_value_set.try(:url)
          version ||= inline_value_set.try(:version)
        end

        canonical(url, version)
      end

      def canonical(url, version)
        return if url.blank?

        version.present? ? "#{url}|#{version}" : url
      end

      def parameter_value(name, value_type)
        request_parameters&.parameter&.find { |param| param.name == name }&.send(value_type)
      end

      def request_parameters
        return @request_parameters if defined?(@request_parameters)

        @request_parameters = parse_request_parameters
      end

      def parse_request_parameters
        return if request.body.string.blank?

        parsed = parse_fhir_object(request.body.string)
        unless parsed.is_a?(FHIR::Parameters)
          raise MockPayer::ParseError,
                "ValueSet/$expand request body must be a Parameters resource, got '#{parsed.resourceType}'."
        end
        parsed
      end

      # test.config.options input references are stored as input names; testers only see the
      # input's title in the Inferno UI, so client-facing messages should use that instead.
      def input_title(input_name)
        test.config.input(input_name.to_sym)&.title || input_name
      end
    end
  end
end
