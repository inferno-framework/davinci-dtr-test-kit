require_relative 'dtr_questionnaire_package_group'
require_relative 'dtr_questionnaire_rendering_group'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_full_ehr_questionnaire_workflow
    title 'Respiratory Assist Device Questionnaire Workflow'
    description %(
      This workflow validates that a DTR Full EHR Client can perform a full DTR Questionnaire workflow using a canned
      Questionnaire for a respiratory assist device order:

      1. Fetch the questionnaire package
      2. Render the questionnaire
    )

    group from: :dtr_questionnaire_package
    group from: :dtr_questionnaire_rendering
  end
end
