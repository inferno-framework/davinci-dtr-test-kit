require_relative 'dtr_full_ehr_questionnaire_package_request_test'
require_relative 'dtr_full_ehr_questionnaire_package_request_validation_test'

module DaVinciDTRTestKit
  class DTRFullEHRQuestionnairePackageGroup < Inferno::TestGroup
    id :dtr_full_ehr_questionnaire_package
    title 'Questionnaire Package Retrieval'
    description %(
      Demonstrate the ability of the EHR to request a questionnaire package from the payer.
    )
    run_as_group

    test from: :dtr_full_ehr_questionnaire_package_request,
         receives_request: :questionnaire_package

    test from: :dtr_full_ehr_questionnaire_package_request_validation,
         uses_request: :questionnaire_package
  end
end
