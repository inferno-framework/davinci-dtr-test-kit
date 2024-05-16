module DaVinciDTRTestKit
  class PayerAdaptiveFormCompleteTest < Inferno::Test
    id :payer_server_adaptive_completion_test
    title 'Adaptive questionnaire was completed.'
    description %(
      This test validates that in the sequence of adaptive responses, one includes a "completed" status.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      assert !scratch[:next_responses].nil?, 'No resources to validate.'
      assert scratch[:next_responses].any? { |r|
               JSON.parse(r.response_body)['status'] == 'completed'
             }, 'Next request sequence did not result in a completed questionnaire.'
    end
  end
end
