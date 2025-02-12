require_relative '../../cql_test'
module DaVinciDTRTestKit
  class DTRCustomQuestionnaireExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_custom_questionnaire_extensions
    title '[USER INPUT VERIFICATION] Custom static questionnaire(s) contain extensions necessary for pre-population'
    description %(
      Inferno checks that the custom response has appropriate extensions and references to libraries within
      those extensions.
    )

    run do
      skip_if scratch[:static_questionnaire_bundles].blank?, 'No questionnaire bundle found in the custom response'
      questionnaires = extract_questionnaires_from_bundles(scratch[:static_questionnaire_bundles])
      verify_questionnaire_extensions(questionnaires)
    end
  end
end
