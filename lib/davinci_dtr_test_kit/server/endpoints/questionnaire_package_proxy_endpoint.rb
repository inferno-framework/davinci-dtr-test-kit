require_relative 'payer_proxy_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class QuestionnairePackageProxyEndpoint < PayerProxyEndpoint
      def outgoing_request_tags
        [QUESTIONNAIRE_TAG]
      end

      def payer_path
        # The v2.0.1 suite allows for a custom endpoint
        session_data.load(test_session_id: result.test_session_id, name: 'custom_endpoint') ||
          '/Questionnaire/$questionnaire-package'
      end
    end
  end
end
