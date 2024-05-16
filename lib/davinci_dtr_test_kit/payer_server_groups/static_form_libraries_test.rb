require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormLibrariesTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_libraries_test
    title 'Questionnaire(s) contains libraries necessary for pre-population'
    description %(
      Inferno check that the payer response contains no duplicate library names
       and that libraries contain cql and elm data.
    )

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:questionnaire_bundle].nil?, 'No questionnaire bundle returned.'
      skip_if initial_static_questionnaire_request.nil?,
              'Population tests only support manual flow - enter initial an initial request.'
      scratch[:library_names] = library_names
      check_libraries(scratch[:questionnaire_bundle])
    end
  end
end
