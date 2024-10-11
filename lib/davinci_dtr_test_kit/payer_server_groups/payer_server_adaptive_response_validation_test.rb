require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormQuestionnaireResponseTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_validation_test
    title 'Validate that the adaptive response conforms to the Output Parameters profile'
    # output :questionnaire_response
    description %(
      This test validates the conformance of the payer's response to the
      [DTR Output Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      profile_with_version = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.0.1'
      endpoint = custom_endpoint.blank? ? '/Questionnaire/$questionnaire-package' : custom_endpoint
      if initial_adaptive_questionnaire_request.nil?
        # making the assumption that only one response was received - if there were multiple, we are only validating the first
        response = load_tagged_requests(QUESTIONNAIRE_TAG)[0]
        scratch[:adaptive_responses] = [response]
        resource = FHIR.from_contents(response.response[:body])
      else
        response = fhir_operation("#{url}#{endpoint}", body: JSON.parse(initial_adaptive_questionnaire_request),
                                                       headers: { 'Content-Type': 'application/json' })
        resource = FHIR.from_contents(response.response[:body])
        scratch[:adaptive_responses] = [response]
      end

      assert !scratch[:adaptive_responses].nil?, 'No resources to validate.'
      assert_response_status([200, 201], response: response.response)
      assert_resource_type(:parameters, resource:)
      assert_valid_resource(resource:, profile_url: profile_with_version)
      questionnaire_bundle = resource.parameter.find { |param| param.resource.resourceType == 'Bundle' }&.resource
      assert questionnaire_bundle, 'No questionnaire bundle found in the response'
      assert_valid_resource(resource: questionnaire_bundle, profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle|2.0.1')
    end
  end
end
