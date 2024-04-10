require_relative 'ext/inferno_core/runnable'
require_relative 'ext/inferno_core/record_response_route'
require_relative 'ext/inferno_core/request'
require_relative 'payer_server_groups/payer_server_static_group'
require_relative 'payer_server_groups/payer_server_adaptive_group'
require_relative 'payer_server_groups/payer_server_adaptive_next_group'

require_relative 'mock_payer'

module DaVinciDTRTestKit
  class DTRPayerServerSuite < Inferno::TestSuite
    extend MockPayer

    id :dtr_payer_server
    title 'Da Vinci DTR Payer Server Test Suite'
      description %(
        # Da Vinci DTR Payer Server Test Suite

        This suite validates that a payer server can act as a source
        of questionnaires for a DTR application to complete. Inferno
        will act as a DTR application requesting questionnaires from
        the system under test.
      )

    # These inputs will be available to all tests in this suite
    input :url,
    title: 'FHIR Server Base Url'

    input :credentials,
        title: 'OAuth Credentials',
        type: :oauth_credentials,
        optional: true

    # All FHIR requests in this suite will use this FHIR client
    fhir_client do
    url :url
    oauth_credentials :credentials
    end

    # All FHIR validation requsets will use this FHIR validator
    validator do
      url ENV.fetch('VALIDATOR_URL')
    end

    # Handle pre-flight request to establish CORS
    pre_flight_handler = proc do
      [
        200,
        {
          'Access-Control-Allow-Origin' => 'http://localhost:3005',
          'Access-Control-Allow-Headers' => 'Content-Type, Authorization'
        },
        ['']
      ]
    end
    route(:options, '/fhir/Questionnaire/$questionnaire-package', pre_flight_handler)
    route(:options, '/fhir/$next-question', pre_flight_handler)

    record_response_route :post, TOKEN_PATH, 'dtr_auth', method(:token_response) do |request|
      DTRPayerServerSuite.extract_client_id(request)
    end

    record_response_route :post, '/fhir/Questionnaire/$questionnaire-package', 'payer_server_questionnaire_package',
                          method(:questionnaire_package_response) do |request|
      DTRPayerServerSuite.extract_bearer_token(request)
    end

    record_response_route :post, '/fhir/$next-question', 'payer_server_adaptive_questionnaire_package',
                          method(:questionnaire_next_response) do |request|
      DTRPayerServerSuite.extract_bearer_token(request)
    end

    group from: :payer_server_static_package
    group from: :payer_server_adaptive_package
    group from: :payer_server_adaptive_next_package
  end
end