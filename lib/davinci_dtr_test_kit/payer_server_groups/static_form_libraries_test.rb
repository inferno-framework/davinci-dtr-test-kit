require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormLibrariesTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_libraries_test
    title 'Parameters contain libraries necessary for pre-population'
    description %(
      Inferno check that the payer response contains no duplicate library names
       and that libraries contain cql and elm data.
    )

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:static_questionnaire_bundles].blank?, 'No questionnaire bundle returned.'
      check_libraries(scratch[:static_questionnaire_bundles])
    end
  end
end
