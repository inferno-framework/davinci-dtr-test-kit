require_relative '../../cql_test'
module DaVinciDTRTestKit
  class DTRCustomQuestionnaireLibrariesTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_custom_questionnaire_libraries
    title %(
      [USER INPUT VERIFICATION] Custom Questionnaire Package response parameters contain libraries
      necessary for pre-population
    )
    description %(
      Inferno check that the custom response contains no duplicate library names
      and that libraries contain cql and elm data.
    )

    def form_type
      config.options[:form_type] || 'static'
    end

    run do
      skip_if scratch[:"#{form_type}_questionnaire_bundles"].blank?,
              'No questionnaire bundle found in the custom response'
      check_libraries(scratch[:"#{form_type}_questionnaire_bundles"])
    end
  end
end
