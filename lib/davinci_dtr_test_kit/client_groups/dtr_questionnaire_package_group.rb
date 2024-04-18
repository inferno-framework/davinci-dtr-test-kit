require_relative 'dtr_questionnaire_package_request_test'
require_relative 'dtr_questionnaire_package_request_validation_test'

module DaVinciDTRTestKit
  class DTRQuestionnairePackageGroup < Inferno::TestGroup
    id :dtr_questionnaire_package
    title 'Questionnaire Package Retrieval'
    description %(
      Demonstrate the ability to request the Respiratory Assist Device Questionnaire Package from the payer.
    )
    run_as_group

    test from: :dtr_questionnaire_package_request,
         receives_request: :questionnaire_package

    test from: :dtr_questionnaire_package_request_validation,
         uses_request: :questionnaire_package
  end
end
