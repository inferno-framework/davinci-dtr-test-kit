require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'payer_server_groups/payer_server_static_group'
require_relative 'payer_server_groups/payer_server_adaptive_group'
require_relative 'tags'
require_relative 'mock_payer'
require_relative 'version'

module DaVinciDTRTestKit
  class DTRPayerServerSuite < Inferno::TestSuite
    extend MockPayer

    id :dtr_payer_server
    title 'Da Vinci DTR Payer Server Test Suite'
    description File.read(File.join(__dir__, 'docs', 'dtr_payer_server_suite_description_v201.md'))

    version VERSION
    # These inputs will be available to all tests in this suite

    input :retrieval_method,
          title: 'Questionnaire Retrieval Method',
          type: 'radio',
          default: 'Both',
          options: {
            list_options: [
              {
                label: 'Static',
                value: 'Static'
              },
              {
                label: 'Adaptive',
                value: 'Adaptive'
              },
              {
                label: 'Both',
                value: 'Both'
              }
            ]
          }

    input :url,
          title: 'FHIR Server Base Url',
          description: 'Required for All Flows'

    input :access_token,
          optional: true,
          title: 'Access Token',
          description: 'DTR Client Flow'

    input :custom_endpoint,
          optional: true,
          title: 'Custom Endpoint for Accessing a Particular Resource',
          description: 'Either Flow (optional)'

    input :credentials,
          title: 'OAuth Credentials',
          type: :oauth_credentials,
          optional: true

    input_order :retrieval_method,
                :url,
                :access_token,
                :custom_endpoint,
                :initial_static_questionnaire_request,
                :initial_adaptive_questionnaire_request,
                :next_question_requests,
                :credentials

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
      url :url
      oauth_credentials :credentials
    end

    # All FHIR validation requsets will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    allow_cors QUESTIONNAIRE_PACKAGE_PATH, NEXT_PATH

    record_response_route :post, TOKEN_PATH, 'dtr_auth', method(:token_response) do |request|
      DTRPayerServerSuite.extract_client_id(request)
    end

    record_response_route :post, '/fhir/Questionnaire/$questionnaire-package', QUESTIONNAIRE_TAG,
                          method(:payer_questionnaire_response), resumes: method(:test_resumes?) do |request|
      DTRPayerServerSuite.extract_bearer_token(request)
    end

    record_response_route :post, '/fhir/Questionnaire/$next-question', NEXT_TAG,
                          method(:questionnaire_next_response), resumes: method(:test_resumes?) do |request|
      DTRPayerServerSuite.extract_bearer_token(request)
    end

    resume_test_route :get, RESUME_PASS_PATH do |request|
      DTRPayerServerSuite.extract_token_from_query_params(request)
    end

    group from: :payer_server_static_package
    group from: :payer_server_adaptive_questionnaire
  end
end
