require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'full_ehr_groups/dtr_full_ehr_questionnaire_package_group'
require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'mock_payer'

module DaVinciDTRTestKit
  class DTRFullEHRSuite < Inferno::TestSuite
    extend MockPayer

    id :dtr_full_ehr
    title 'Da Vinci DTR Full EHR Test Suite'
    description %(
        # Da Vinci DTR Full EHR Test Suite

        This suite validates that an EHR or other application can act
        as a full DTR application requesting questionnaires from a
        payer server and using local data to complete and store them.
        Inferno will act as payer server returning questionnaires
        in response to queries from the system under test and validating
        that they can be completed as expected.
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
    route(:options, '/fhir/Questionnaire/$questionnaire-package', pre_flight_handler)

    record_response_route :post, TOKEN_PATH, 'dtr_auth', method(:token_response) do |request|
      DTRFullEHRSuite.extract_client_id(request)
    end

    record_response_route :post, '/fhir/Questionnaire/$questionnaire-package', 'dtr_full_ehr_questionnaire_package',
                          method(:questionnaire_package_response) do |request|
      DTRFullEHRSuite.extract_bearer_token(request)
    end

    resume_test_route :get, RESUME_PASS_PATH do |request|
      DTRFullEHRSuite.extract_token_from_query_params(request)
    end

    resume_test_route :get, RESUME_FAIL_PATH, result: 'fail' do |request|
      DTRFullEHRSuite.extract_token_from_query_params(request)
    end

    group from: :oauth2_authentication
    group from: :dtr_full_ehr_questionnaire_package
  end
end
