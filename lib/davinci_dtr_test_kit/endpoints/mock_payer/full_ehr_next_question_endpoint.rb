require_relative 'next_question_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRNextQuestionEndpoint < NextQuestionEndpoint
      def test_run_identifier
        request.headers['authorization']&.delete_prefix('Bearer ')
      end
    end
  end
end
