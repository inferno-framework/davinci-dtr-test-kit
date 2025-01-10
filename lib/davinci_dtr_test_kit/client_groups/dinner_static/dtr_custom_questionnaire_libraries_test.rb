require_relative '../../cql_test'
module DaVinciDTRTestKit
  class DTRCustomQuestionnaireLibrariesTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_custom_questionnaire_libraries
    title 'Custom Questionnaire Package response parameters contain libraries necessary for pre-population'
    description %(
      Inferno check that the custom response contains no duplicate library names
      and that libraries contain cql and elm data.
    )
    input :custom_questionnaire_package_response, optional: true

    run do
      omit_if custom_questionnaire_package_response.blank?, 'Custom response was not provided'
      skip_if scratch[:static_questionnaire_bundles].blank?, 'No questionnaire bundle found in the custom response'
      check_libraries(scratch[:static_questionnaire_bundles])
    end
  end
end
