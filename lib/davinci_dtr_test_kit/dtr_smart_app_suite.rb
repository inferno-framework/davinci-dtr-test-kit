require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'client_groups/dtr_smart_app_questionnaire_workflow_group'
require_relative 'mock_payer'

module DaVinciDTRTestKit
  class DTRSmartAppSuite < Inferno::TestSuite
    extend MockPayer

    id :dtr_smart_app
    title 'Da Vinci DTR Smart App Test Suite'
    description %(
        # Da Vinci DTR Smart App Test Suite

        This suite validates that a DTR Smart App can interact
        with a payer server and a light DTR EMR to complete
        questionnaires. Inferno will act as a payer server returning
        questionnaires in response to requests from the system under
        test and also as a light DTR EMR responding to requests for
        data.
      )

    # All FHIR validation requsets will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    # Handle pre-flight request to establish CORS
    pre_flight_handler = proc do
      [
        200,
        {
          'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
        },
        ['']
      ]
    end
    route(:options, QUESTIONNAIRE_PACKAGE_PATH, pre_flight_handler)

    record_response_route :post, TOKEN_PATH, 'dtr_auth', method(:token_response) do |request|
      DTRSmartAppSuite.extract_client_id(request)
    end

    record_response_route :post, QUESTIONNAIRE_PACKAGE_PATH, 'dtr_smart_app_questionnaire_package',
                          method(:questionnaire_package_response) do |request|
      DTRSmartAppSuite.extract_bearer_token(request)
    end

    record_response_route :post, QUESTIONNAIRE_RESPONSE_PATH, 'dtr_smart_app_questionnaire_response',
                          method(:questionnaire_response_response) do |request|
      DTRSmartAppSuite.extract_bearer_token(request)
    end

    resume_test_route :get, RESUME_PASS_PATH do |request|
      DTRSmartAppSuite.extract_token_from_query_params(request)
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      DTRSmartAppSuite.extract_token_from_query_params(request)
    end

    group from: :oauth2_authentication
    group from: :dtr_smart_app_questionnaire_workflow
  end
end
