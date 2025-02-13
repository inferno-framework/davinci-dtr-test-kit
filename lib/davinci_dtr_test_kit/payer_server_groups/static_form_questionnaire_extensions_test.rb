require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_extensions_test
    title 'Static questionnaire(s) contain extensions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has appropriate extensions and references to libraries within
      those extensions.
    )

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:static_questionnaire_bundles].blank?, 'No questionnaire bundle returned.'
      questionnaires = extract_questionnaires_from_bundles(scratch[:static_questionnaire_bundles])
      verify_questionnaire_extensions(questionnaires)
    end
  end
end
