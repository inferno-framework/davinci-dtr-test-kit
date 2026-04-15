module DaVinciDTRTestKit
  class PayerAdaptiveFormCompleteTest < Inferno::Test
    id :payer_server_adaptive_completion_test
    title 'Adaptive questionnaire was completed.'
    description %(
      This test validates that in the sequence of adaptive responses, one includes a "completed" status.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@219'

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      assert !scratch[:next_question_questionnaire_responses].nil?, 'No resources to validate.'
      assert scratch[:next_question_questionnaire_responses].any? { |qr| qr.status == 'completed' },
             'Next request sequence did not result in a completed questionnaire.'
      scratch[:next_question_questionnaire_responses] = nil
    end
  end
end
