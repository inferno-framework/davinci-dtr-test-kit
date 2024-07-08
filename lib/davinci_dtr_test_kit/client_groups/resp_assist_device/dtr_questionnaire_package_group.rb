require_relative 'dtr_resp_questionnaire_package_request_test'
require_relative '../shared/dtr_questionnaire_package_request_validation_test'

module DaVinciDTRTestKit
  class DTRQuestionnairePackageGroup < Inferno::TestGroup
    id :dtr_questionnaire_package
    title 'Questionnaire Package Retrieval'
    description %(
      Demonstrate the ability to request the Respiratory Assist Device Questionnaire Package from the payer.
    )
    run_as_group

    test from: :dtr_resp_questionnaire_package_request
    test from: :dtr_questionnaire_package_request_validation
  end
end
