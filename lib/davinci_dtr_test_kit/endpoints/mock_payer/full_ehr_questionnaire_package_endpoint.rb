require_relative 'questionnaire_package_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class FullEHRQuestionnairePackageEndpoint < QuestionnairePackageEndpoint
      def test_run_identifier
        request.headers['authorization']&.delete_prefix('Bearer ')
      end
    end
  end
end
