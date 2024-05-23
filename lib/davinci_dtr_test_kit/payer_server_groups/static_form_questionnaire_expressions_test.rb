require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormExpressionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_expressions_test
    title 'Questionnaire(s) contains expressions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has apprporiate expressions and that expressions are
       written in cql.
    )

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:questionnaire_bundle].nil?, 'No questionnaire bundle returned.'
      check_questionnaire_expressions(scratch[:questionnaire_bundle])
      scratch[:questionnaire_bundle] = nil
    end
  end
end
