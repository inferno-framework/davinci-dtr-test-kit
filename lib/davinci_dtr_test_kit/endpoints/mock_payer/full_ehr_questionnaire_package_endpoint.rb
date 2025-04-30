require 'udap_security_test_kit'
require_relative 'questionnaire_package_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRQuestionnairePackageEndpoint < QuestionnairePackageEndpoint
      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        UDAPSecurityTestKit::MockUDAPServer.issued_token_to_client_id(
          request.headers['authorization']&.delete_prefix('Bearer ')
        )
      end

      def make_response
        return if response.status == 401 # set in update_result (expired token handling there)

        super
      end

      def update_result
        if UDAPSecurityTestKit::MockUDAPServer.request_has_expired_token?(request)
          UDAPSecurityTestKit::MockUDAPServer.update_response_for_expired_token(response)
          return
        end

        super
      end
    end
  end
end
