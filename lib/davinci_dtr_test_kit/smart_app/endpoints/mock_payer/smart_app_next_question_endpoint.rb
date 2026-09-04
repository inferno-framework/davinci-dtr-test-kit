require_relative '../mock_authorization'
require_relative '../../../full_ehr/v2.0.1/full_ehr_next_question_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class SMARTAppNextQuestionEndpoint < FullEHRNextQuestionEndpoint
      def test_run_identifier
        MockAuthorization.extract_client_id_from_bearer_token(request)
      end
    end
  end
end
