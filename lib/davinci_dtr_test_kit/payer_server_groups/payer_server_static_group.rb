require_relative 'static_form_test'

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

          )
    id :payer_server_static_package
    run_as_group

    input :url,
          optional: true,
          title: 'FHIR Server Base Url'

    input :questionnaire_parameters,
          title: 'Questionnaire Parameters',
          description: 'Input Questionnaire Parameters',
          type: 'textarea'

    test from: :dtr_v201_payer_static_form_test
  end
end
