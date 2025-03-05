require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerAdaptiveNexQuestionExtensionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_next_question_extensions_test
    title 'Adaptive Next Question questionnaire(s) contain extensions necessary for pre-population'
    description %(
      Inferno checks that the payer server response has appropriate extensions and references to libraries within
      those extensions.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@62', 'hl7.fhir.us.davinci-dtr_2.0.1@83',
                          'hl7.fhir.us.davinci-dtr_2.0.1@98'

    run do
      skip_if retrieval_method == 'Static',
              'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:next_question_questionnaire_responses].nil?, 'No questionnaires returned.'
      questionnaires = extract_contained_questionnaires(scratch[:next_question_questionnaire_responses])
      verify_questionnaire_extensions(questionnaires)
    end
  end
end
