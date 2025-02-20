require_relative 'dtr_questionnaire_package_group'
require_relative 'dtr_questionnaire_rendering_group'
require_relative 'dtr_questionnaire_response_group'

module DaVinciDTRTestKit
  class DTRSmartAppQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_resp_workflow
    title 'Respiratory Assist Device Questionnaire Workflow'
    description %(
      This workflow validates that a DTR SMART App can perform a full DTR
      Questionnaire workflow using a canned Questionnaire
      for a respiratory assist device order:

      1. Fetch the questionnaire package ([RespiratoryAssistDevices](https://github.com/inferno-framework/davinci-dtr-test-kit/blob/main/lib/davinci_dtr_test_kit/fixtures/questionnaire_package.json))
      2. Render the questionnaire
      3. Pre-populate the questionnaire response
    )

    group from: :dtr_resp_questionnaire_package
    group from: :dtr_resp_rendering
    group from: :dtr_resp_response
  end
end
