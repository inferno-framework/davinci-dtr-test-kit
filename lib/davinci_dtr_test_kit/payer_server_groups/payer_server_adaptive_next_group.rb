require_relative 'payer_server_adaptive_next_request_test'
require_relative 'payer_server_next_request_validation_test'
require_relative 'payer_server_next_response_validation_test'

module DaVinciDTRTestKit
  class DTRPayerServerAdaptiveNextQuestionnairePackageGroup < Inferno::TestGroup
    title 'Next Question Retrieval'
    description %(
      Demonstrate the ability of the EHR to request the next question in an adaptive questionnaire from the payer.
    )
    id :payer_server_adaptive_next_package
    run_as_group

    # get the next request
    test from: :payer_server_next_questionnaire_request,
         receives_request: :adaptive_questionnaire_package

    # optionally validate the client request
    test from: :payer_server_next_request_validation,
         receives_request: :adaptive_questionnaire_package

    # pass request to payer server, validate adaptive questionnaire response
    test from: :payer_server_next_response_validation_test,
         uses_request: :adaptive_questionnaire_package 

  end
end
