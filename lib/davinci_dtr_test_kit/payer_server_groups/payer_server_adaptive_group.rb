require_relative 'adaptive_request_test'
require_relative 'adaptive_request_validation_test'
require_relative 'payer_adaptive_request_test'

module DaVinciDTRTestKit
  class DTRPayerServerAdaptiveQuestionnairePackageGroup < Inferno::TestGroup
    title 'Questionnaire Package Retrieval'
    description %(
      Demonstrate the ability of the EHR to request a questionnaire package from the payer.
    )
    id :payer_server_adaptive_package
    run_as_group

    # receive client request
    test from: :payer_server_questionnaire_package_request,
         receives_request: :client_questionnaire_package

    # optionally validate client request
    test from: :payer_server_adaptive_questionnaire_package_request_validation,
         uses_request: :client_questionnaire_package
    
    # pass request to payer server, validate questionnaire response
    test from: :payer_adaptive_request_test,
         uses_request: :client_questionnaire_package

    #TODO: add these tests back once the full loop of adaptive questions completes in the record_response_route
    # pass questionnaire response to client, validate $next-question request
    # test from: :payer_server_next_questionnaire_request,
    #      receives_request: :questionnaire_package

    # pass request to payer server, validate adaptive questionnaire response
    # test from: :payer_adaptive_request_test,
    #      uses_request: :questionnaire_package

  end
end
