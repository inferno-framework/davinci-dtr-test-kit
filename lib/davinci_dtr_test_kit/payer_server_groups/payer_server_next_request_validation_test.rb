require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextRequestTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    title 'User Input Validation:  Next Question request is valid'
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
      if next_question_requests.nil?
        resources = load_tagged_requests(NEXT_TAG)
        using_manual_entry = false
        skip_if resources.nil?, 'No plain resources to validate.'
        json_resources = resources.map { |r| JSON.parse(r.request_body) }
      else
        resources = next_question_requests
        json_resources = JSON.parse(resources)
        using_manual_entry = true
      end
      skip_if json_resources.nil?, 'No json resources to validate.'
      if json_resources.any? { |r| r['resourceType'] == 'QuestionnaireResponse' }
        perform_request_validation_test(
          resources,
          :questionnaireResponse,
          'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt',
          next_url,
          using_manual_entry
        )
      elsif json_resources.any? { |r| r['resourceType'] == 'Parameters' }
        perform_request_validation_test(
          resources,
          :parameters,
          'http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in',
          next_url,
          using_manual_entry
        )
      else
        messages << { type: 'error',
                      message: format_markdown("No resources were of type 'Parameters' or 'QuestionnaireResponse'") }
      end
      errors_found = messages.any? { |message| message[:type] == 'error' }
      skip_if errors_found, "No resources conform to the profiles http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt
        or http://hl7.org/fhir/uv/sdc/StructureDefinition/parameters-questionnaire-next-question-in"
    end
  end
end
