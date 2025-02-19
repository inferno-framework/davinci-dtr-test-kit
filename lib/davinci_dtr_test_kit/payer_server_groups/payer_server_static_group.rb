require_relative 'static_form_request_test'
require_relative 'static_form_request_validation_test'
require_relative 'static_form_response_validation_test'
require_relative 'static_form_libraries_test'
require_relative 'static_form_questionnaire_extensions_test'
require_relative 'static_form_questionnaire_expressions_test'

module DaVinciDTRTestKit
  class DTRPayerServerQuestionnairePackageGroup < Inferno::TestGroup
    title 'Static Questionnaire Package Retrieval'
    short_description 'Verify support for the payer server capabilities required to provide
    appropriate questionnaire packages upon request.'
    description %(
    ## Background

    The DTR Payer Server sequence verifies that the system under test is
    able to provide correct responses for questionnaire package queries. These queries
    must contain resources conforming to the questionnaire-package as
    specified in the DTR v2.0.1 Implementation Guide.

    ## Testing Work Flow Options

      - Enter the `FHIR Server Base Url` and `Access Token` if you are connecting a client that will
       provide inferno with requests to be tested and sent to the server under test.
       These inputs must align with the configuration of the DTR client being used to provide requests.

      - Enter the `Initial Static Questionnaire Request`, in addition to the
      `FHIR Server Base Url` pointing to the payer server,
      to provide the json requests manually, rather than relying on a DTR client.
          )
    id :payer_server_static_package
    run_as_group

    input :initial_static_questionnaire_request,
          optional: true,
          title: 'Initial Static Questionnaire Request',
          description: 'Manual Flow',
          type: 'textarea'

    input :access_token, :retrieval_method

    input_order :retrieval_method,
                :access_token,
                :initial_static_questionnaire_request

    test from: :dtr_v201_payer_static_request_test, receives_request: :static_questionnaire_request
    test from: :dtr_v201_payer_static_form_request_validation_test
    test from: :dtr_v201_payer_static_form_response_test
    test from: :dtr_v201_payer_static_form_libraries_test
    test from: :dtr_v201_payer_static_form_extensions_test
    test from: :dtr_v201_payer_static_form_expressions_test
  end
end
