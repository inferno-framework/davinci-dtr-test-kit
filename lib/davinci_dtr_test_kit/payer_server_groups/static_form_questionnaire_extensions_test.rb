require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_extensions_test
    title 'Questionnaire(s) contains extensions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has apprporiate extensions and references to libraries within
      those extensions.
    )

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:questionnaire_bundle].nil?, 'No questionnaire bundle returned.'
      skip_if initial_static_questionnaire_request.nil?,
              'Population tests only support manual flow - enter initial an initial request.'
      check_questionnaire_extensions(scratch[:questionnaire_bundle])
    end
  end
end
