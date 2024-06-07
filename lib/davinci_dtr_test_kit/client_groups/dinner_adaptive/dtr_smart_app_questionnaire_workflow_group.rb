module DaVinciDTRTestKit
  class DTRSmartAppAdaptiveDinnerQuestionnaireWorkflowGroup < Inferno::TestGroup
    id :dtr_smart_app_adaptive_dinner_questionnaire_workflow
    title 'Adaptive Questionnaire Workflow'
    description %(
      This test validates that a DTR SMART App client can perform a full DTR Adaptive Questionnaire workflow
      using a mocked questionnaire requesting what a patient wants for dinner. The client system must
      demonstrate their ability to:

      1. Fetch the adaptive questionnaire package
      2. Fetch the first set of questions and render and pre-populate them appropriately, including:
         - fetch additional data needed for pre-population
         - pre-populate data as directed by the questionnaire
         - display questions only when they are enabled
      3. Answer the initial questions and request additional questions
      4. Complete the questionnaire and provide the completed QuestionnaireResponse
         with appropriate indicators for pre-populated and manually-entered data.
    )
  end
end
