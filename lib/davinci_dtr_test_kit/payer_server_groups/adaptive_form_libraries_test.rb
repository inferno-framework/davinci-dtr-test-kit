require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormLibrariesTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_form_libraries_test
    title 'Parameters contain libraries necessary for pre-population'
    description %(
      Inferno check that the payer response contains no duplicate library names
       and that libraries contain cql and elm data.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@95', 'hl7.fhir.us.davinci-dtr_2.0.1@96',
                          'hl7.fhir.us.davinci-dtr_2.0.1@99', 'hl7.fhir.us.davinci-dtr_2.0.1@101',
                          'hl7.fhir.us.davinci-dtr_2.0.1@102'

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:adaptive_questionnaire_bundles].blank?, 'No questionnaire bundle returned.'
      check_libraries(scratch[:adaptive_questionnaire_bundles])
    end
  end
end
