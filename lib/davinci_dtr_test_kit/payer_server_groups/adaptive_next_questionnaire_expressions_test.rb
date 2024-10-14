require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormExpressionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_next_form_expressions_test
    title 'Questionnaire(s) contains items with expressions necessary for pre-population'
    description %(
      Inferno checks that the payer server response to $next-question operation has appropriate expressions and that
      expressions are written in cql.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:next_responses].nil?, 'No questionnaires returned.'
      questionnaire_items_test(scratch[:next_responses], final_cql_test: true)
      scratch[:next_responses] = nil
    end
  end
end
