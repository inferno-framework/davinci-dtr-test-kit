require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormExpressionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_expressions_test
    title 'Static questionnaire(s) contain items with expressions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has appropriate expressions and that expressions are
       written in cql.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@64'

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:static_questionnaire_bundles].blank?, 'No questionnaire bundle returned.'
      questionnaires = extract_questionnaires_from_bundles(scratch[:static_questionnaire_bundles])
      verify_questionnaire_items(questionnaires, final_cql_test: true)
      scratch[:static_questionnaire_bundles] = nil
    end
  end
end
