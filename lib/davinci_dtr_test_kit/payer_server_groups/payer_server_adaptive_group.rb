require_relative 'payer_server_adaptive_request_test'
require_relative 'payer_server_adaptive_request_validation_test'
require_relative 'payer_server_adaptive_response_validation_test'
require_relative 'payer_server_next_request_validation_test'
require_relative 'payer_server_next_response_validation_test'

module DaVinciDTRTestKit
  class DTRPayerServerAdaptiveQuestionnairePackageGroup < Inferno::TestGroup
    title 'Adaptive Questionnaire Retrieval'
    description %(
      Demonstrate the ability of the Payer Server to provide an adaptive questionnaire following requests from the DTR Client.
    )
    id :payer_server_adaptive_questionnaire
    run_as_group
    input :adaptive_endpoint,
      optional: true,
      title: "Endpoint for a Particular Adaptive Resource"

    # receive client request
    test from: :payer_server_questionnaire_request,
         receives_request: :client_questionnaire_package

    # optionally validate client request
    test from: :payer_server_adaptive_questionnaire_request_validation
    
    # pass request to payer server, validate questionnaire response
    test from: :payer_server_adaptive_response_validation_test 

    # optionally validate the client request
    test from: :payer_server_next_request_validation

    # pass request to payer server, validate adaptive questionnaire response
    test from: :payer_server_next_response_validation_test

  end
end
