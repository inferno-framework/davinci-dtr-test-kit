require 'udap_security_test_kit'
require_relative '../endpoints/mock_payer'
require_relative '../../tags'

module DaVinciDTRTestKit
  module MockPayer
    # Simulates the payer's Questionnaire/$log-questionnaire-errors operation
    # (https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-log-questionnaire-errors.html).
    # The operation has no output parameters, so any request associated with a waiting session is
    # recorded and answered with an empty 200 response. The request body is not checked here:
    # conformance of the submitted Parameters is verified by tests run after the interaction.
    class FullEHRV220LogQuestionnaireErrorsEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
          request.headers['authorization']&.delete_prefix('Bearer ')
        )
      end

      def tags
        tags = [CLIENT_LOG_QUESTIONNAIRE_ERRORS_TAG]
        tags << test.config.options[:dtr_workflow_tag] if test.config.options[:dtr_workflow_tag].present?
        tags
      end

      def make_response
        response.headers['Access-Control-Allow-Origin'] = '*'
        return if response.status == 401 # response set in update_result (expired token handling there)

        response.status = 200
      end

      def update_result
        return unless UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)

        UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response, 'Bearer token')
      end
    end
  end
end
