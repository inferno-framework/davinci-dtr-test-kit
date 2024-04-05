require_relative 'static_form_test'

module DaVinciDTRTestKit
  class DTRPayerServerQuestionnairePackageGroup < Inferno::TestGroup
    title 'Payer Server Tests'
    short_description 'Verify support for the payer server capabilities required to provide appropriate questionnaire packages upon request.'
    description %(
    # Background

    The DTR Payer Server sequence verifies that the system under test is
    able to provide correct responses for questionnaire package queries. These queries
    must contain resources conforming to the questionnaire-package as
    specified in the DTR v2.0.1 Implementation Guide.

    # Testing Methodology
    ## Static Forms

    ## Adaptive Forms

    ## Reporting an Error

    ## Questionnaire Package Parameters

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the Basic resources found in the first test for these
    elements.

    ## Profile Validation
          )
    id :payer_server_static_package
    run_as_group

    input :questionnaire_parameters,
    title: 'Questionnaire Parameters',
    description: 'Input Questionnaire Parameters',
    type: 'textarea'

    test from: :dtr_v201_payer_static_form_test
  end
end