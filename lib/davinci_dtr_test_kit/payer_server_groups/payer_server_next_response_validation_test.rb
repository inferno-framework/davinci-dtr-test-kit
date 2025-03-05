require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextResponseTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_next_response_validation_test
    title 'Inferno sends payer server a request for subsequent adaptive forms - validate the responses'
    description %(
      This test validates the conformance of the payer's response to the
      [SDC Questionnaire Response](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@169'

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      reqs = if next_question_requests.nil?
               load_tagged_requests(NEXT_TAG)
             else
               json_requests = JSON.parse(next_question_requests)
               json_requests.map do |resource|
                 fhir_operation("#{url}/Questionnaire/$next-question",
                                body: resource,
                                headers: { 'Content-Type': 'application/fhir+json' })
               end
             end
      assert !reqs.nil?, 'No requests to validate.'
      scratch[:next_question_questionnaire_responses] = reqs.map do |req|
        assert_response_status([200, 202], request: req)
        FHIR.from_contents(req.response_body)
      end

      perform_response_validation_test(
        scratch[:next_question_questionnaire_responses],
        :questionnaireResponse,
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse'
      )
      errors_found = messages.any? { |message| message[:type] == 'error' }
      skip_if errors_found, "No resources conform to the profiles http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt
        or http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in"
    end
  end
end
