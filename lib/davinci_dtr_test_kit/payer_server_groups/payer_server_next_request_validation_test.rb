require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextRequestTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    title '[USER INPUT VALIDATION] Next Question request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [SDC Parameters Next Question In](http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.
    )
    id :payer_server_next_request_validation

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if access_token.nil? && next_question_requests.nil?, 'No access token or request resources provided.'
      resources = if next_question_requests.nil?
                    load_tagged_requests(NEXT_TAG)
                  else
                    next_question_requests
                  end
      perform_request_validation_test(
        resources,
        :questionnaireResponse,
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in',
        next_url
      )
    rescue Inferno::Exceptions::AssertionException => e
      msg = e.message.to_s.strip
      skip msg
    end
  end
end
