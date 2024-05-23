require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormExpressionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_form_expressions_test
    title 'Questionnaire(s) contains expressions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has apprporiate expressions and that expressions are
       written in cql.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:adaptive_responses].nil?, 'No questionnaire bundle returned.'
      questionnaire_expressions_test(scratch[:adaptive_responses], final_cql_test: false)
      scratch[:adaptive_responses] = nil
    end
  end
end
