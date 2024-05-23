require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_form_extensions_test
    title 'Questionnaire(s) contains extensions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has apprporiate extensions and references to libraries within
      those extensions.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:adaptive_responses].nil?, 'No questionnaire bundle returned.'
      questionnaire_extensions_test(scratch[:adaptive_responses])
    end
  end
end
