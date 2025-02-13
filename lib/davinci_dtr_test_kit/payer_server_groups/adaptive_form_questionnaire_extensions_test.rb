require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_form_extensions_test
    title 'Questionnaire(s) contains extensions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has appropriate extensions and references to libraries within
      those extensions.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:adaptive_questionnaire_bundles].nil?, 'No questionnaire bundle returned.'
      questionnaires = extract_questionnaires_from_bundles(scratch[:adaptive_questionnaire_bundles])
      verify_questionnaire_extensions(questionnaires)
    end
  end
end
