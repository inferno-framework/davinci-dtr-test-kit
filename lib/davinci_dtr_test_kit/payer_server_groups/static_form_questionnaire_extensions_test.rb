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
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@57', 'hl7.fhir.us.davinci-dtr_2.0.1@62',
                          'hl7.fhir.us.davinci-dtr_2.0.1@83', 'hl7.fhir.us.davinci-dtr_2.0.1@98',
                          'hl7.fhir.us.davinci-dtr_2.0.1@309', 'hl7.fhir.us.davinci-dtr_2.0.1@317'

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      skip_if scratch[:static_questionnaire_bundles].blank?, 'No questionnaire bundle returned.'
      questionnaires = extract_questionnaires_from_bundles(scratch[:static_questionnaire_bundles])
      verify_questionnaire_extensions(questionnaires)
    end
  end
end
