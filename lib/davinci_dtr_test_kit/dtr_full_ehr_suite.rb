require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'client_groups/resp_assist_device/dtr_full_ehr_questionnaire_workflow_group'
require_relative 'auth_groups/oauth2_authentication_group'
require_relative 'mock_payer'
require_relative 'version'

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

    version VERSION

    # All FHIR validation requsets will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    allow_cors QUESTIONNAIRE_PACKAGE_PATH

    record_response_route :post, TOKEN_PATH, 'dtr_auth', method(:token_response) do |request|
      DTRFullEHRSuite.extract_client_id(request)
    end

    record_response_route :post, '/fhir/Questionnaire/$questionnaire-package', QUESTIONNAIRE_PACKAGE_TAG,
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
    group from: :dtr_full_ehr_questionnaire_workflow
  end
end
