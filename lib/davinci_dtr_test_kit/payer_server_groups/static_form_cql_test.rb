require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormCQLTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_static_form_cql_test
    title 'Questionnaire(s) contains population logic'
    optional
    run do
      skip_if scratch[:questionnaire_bundle].nil?, 'No questionnaire bundle returned.'
      check_population_extensions(scratch[:questionnaire_bundle])
    end
  end
end