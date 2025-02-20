require_relative 'dtr_resp_rendering_attestation_test'

module DaVinciDTRTestKit
  class DTRQuestionnaireRenderingGroup < Inferno::TestGroup
    id :dtr_resp_rendering
    title 'Questionnaire Rendering'
    description %(
      Demonstrate the ability to render the Respiratory Assist Device Questionnaire.
    )
    run_as_group

    test from: :dtr_resp_rendering_attest
  end
end
