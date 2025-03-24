require_relative 'next_question_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRNextQuestionEndpoint < NextQuestionEndpoint
      def test_run_identifier
        return request.params[:session_path] if request.params[:session_path].present?

        MockUdapSmartServer.token_to_client_id(request.headers['authorization']&.delete_prefix('Bearer '))
      end

      def make_response
        return if response.status == 401 # set in update_result (expired token handling there)

        super
      end

      def update_result
        if MockUdapSmartServer.request_has_expired_token?(request)
          MockUdapSmartServer.update_response_for_expired_token(response)
          return
        end

        super
      end
    end
  end
end
