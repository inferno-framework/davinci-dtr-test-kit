require_relative 'dtr_questionnaire_rendering_attestation_test'

module DaVinciDTRTestKit
  class DTRQuestionnaireRenderingGroup < Inferno::TestGroup
    id :dtr_questionnaire_rendering
    title 'Questionnaire Rendering'
    description %(
      Demonstrate the ability to render the Respiratory Assist Device Questionnaire.
    )
    run_as_group

    test from: :dtr_questionnaire_rendering_attestation,
         uses_request: :questionnaire_package
  end
end
