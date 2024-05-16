require_relative 'payer_server_adaptive_request_test'
require_relative 'payer_server_adaptive_request_validation_test'
require_relative 'payer_server_adaptive_response_bundles_validation_test'
require_relative 'payer_server_adaptive_response_search_validation_test'
require_relative 'payer_server_adaptive_response_validation_test'
require_relative 'payer_server_next_request_validation_test'
require_relative 'payer_server_next_response_validation_test'
require_relative 'payer_server_next_response_complete_test'

module DaVinciDTRTestKit
  class DTRPayerServerAdaptiveQuestionnairePackageGroup < Inferno::TestGroup
    title 'Adaptive Questionnaire Retrieval'
    description %(

      ## Background

      These tests validate the ability of the Payer Server to provide an adaptive questionnaire
       following requests from the DTR Client. Resources are validated as specified
       in the DTR v2.0.1 Implementation Guide.

      There are several input options, which correspond to different workflows. No inputs are explicitly required,
       but all inputs for at least one work flow must be provided to complete testing (see below).

      ## Testing Work Flow Options

      - Enter the `FHIR Server Base Url` and `Access Token` if you are connecting a client that will provide
       inferno with requests to be tested and sent to the server under test. These inputs must align with
       the configuration of the DTR client being used to provide requests. Optionally,
       an `Endpoint for a Particular Adaptive Resource` can also be provided, which should include the ID
       of the resource of interest (e.g., `/Questionnaire/HomeOxygenTherapyAdditional/$questionnaire-package`).

      - Enter the `Initial Adaptive Questionnaire Request` and a set of  `Next Question Requests`, in addition to the
      `FHIR Server Base Url` pointing to the payer server,
      to provide the json requests manually, rather than relying on a DTR client.
    )
    id :payer_server_adaptive_questionnaire
    run_as_group

    input :initial_adaptive_questionnaire_request,
          optional: true,
          title: 'Initial Adaptive Questionnaire Request',
          description: 'Manual Flow',
          type: 'textarea'

    input :next_question_requests,
          optional: true,
          title: 'Next Question Requests',
          description: 'Manual Flow',
          type: 'textarea'

    input_order :retrieval_method,
                :url,
                :custom_endpoint,
                :access_token,
                :initial_adaptive_questionnaire_request,
                :next_question_requests,
                :credentials

    # receive client request
    test from: :payer_server_questionnaire_request,
         receives_request: :client_questionnaire_package

    # optionally validate client request
    test from: :payer_server_adaptive_questionnaire_request_validation

    # pass request to payer server, validate questionnaire response
    test from: :payer_server_adaptive_response_validation_test
    test from: :payer_server_adaptive_response_bundles_validation_test
    test from: :payer_server_adaptive_response_search_validation_test

    # optionally validate the client request
    test from: :payer_server_next_request_validation

    # pass request to payer server, validate adaptive questionnaire response
    test from: :payer_server_next_response_validation_test
    test from: :payer_server_adaptive_completion_test
  end
end
