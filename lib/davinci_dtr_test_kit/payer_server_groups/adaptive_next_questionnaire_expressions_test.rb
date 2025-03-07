require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerAdaptiveNextQuestionExpressionsTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_v201_payer_adaptive_next_question_expressions_test
    title 'Adaptive Next Question questionnaire(s) contain items with expressions necessary for pre-population'
    description %(
      Inferno checks that the payer server response to $next-question operation has appropriate expressions and that
      expressions are written in cql.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@64'

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if scratch[:next_question_questionnaire_responses].nil?, 'No questionnaires returned.'
      questionnaires = extract_contained_questionnaires(scratch[:next_question_questionnaire_responses])
      verify_questionnaire_items(questionnaires, final_cql_test: true)
    end
  end
end
