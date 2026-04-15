require_relative '../mock_authorization'
require_relative '../../../full_ehr/endpoints/mock_payer/full_ehr_questionnaire_package_endpoint'

module DaVinciDTRTestKit
  module MockPayer
    class SMARTAppQuestionnairePackageEndpoint < FullEHRQuestionnairePackageEndpoint
      def test_run_identifier
        MockAuthorization.extract_client_id_from_bearer_token(request)
      end
    end
  end
end
