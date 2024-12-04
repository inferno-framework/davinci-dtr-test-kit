require_relative '../mock_authorization/mock_authorization'

module DaVinciDTRTestKit
  module MockEHR
    class QuestionnaireResponseEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        MockAuthorization.extract_client_id_from_bearer_token(request)
      end

      def make_response
        response.status = 201
        response.format = :json
        response['Access-Control-Allow-Origin'] = '*'
        response.body = request.body
      end

      def update_result
        results_repo.update_result(result.id, 'pass')
      end
    end
  end
end
