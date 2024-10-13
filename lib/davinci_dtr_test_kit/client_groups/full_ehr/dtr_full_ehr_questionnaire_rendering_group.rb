require_relative 'dtr_full_ehr_prepopulation_attestation_test'
require_relative 'dtr_full_ehr_prepopulation_override_attestation_test'
require_relative 'dtr_full_ehr_rendering_enabled_questions_attestation_test'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireRenderingGroup < Inferno::TestGroup
    id :dtr_full_ehr_questionnaire_rendering
    title 'Filling Out the Questionnaire'
    description %(
        The tester will interact with the questionnaire within their client system
        such that pre-population steps are taken, the qustionnaire is rendered, and
        they are able to fill it out. The tester will attest that questionnaire pre-population
        and rendering directives were followed.
      )
    run_as_group

    # Test 1: attest to the pre-population of the name fields
    test from: :dtr_full_ehr_prepopulation_attestation
    # Test 2: attest to the pre-population and edit of the first name field
    test from: :dtr_full_ehr_prepopulation_override_attestation
    # Test 3: attest to the display of the toppings questions only when a dinner answer is selected
    test from: :dtr_full_ehr_rendering_enabled_questions_attestation
  end
end
