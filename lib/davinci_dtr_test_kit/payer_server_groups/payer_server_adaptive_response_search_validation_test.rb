require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormResponseSearchTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_search_validation_test
    title 'Validate that the adaptive response contains valid Adaptive Form Search resource'
    description %(
      This test validates the conformance of the payer's response to the
      [DTR Questionnaire for Adaptive Form Search](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt-search)
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
      skip_if access_token.nil? && initial_questionnaire_request.nil?, 'No access token or request resource provided.'
      test_passed = false
      profile_url = "http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt-search"
      scratch[:adaptive_responses].each_with_index do |resource, index|
        fhir_resource = FHIR.from_contents(resource.response[:body])
        fhir_resource.parameter.each do |param|
          begin
            resource_is_valid = validate_resource(param.resource, :bundle, profile_url, index)
            if resource_is_valid
              test_passed = true
            end
          rescue => e
            next
          end
        end
      end
      if !test_passed && !tests_failed[profile_url].blank?
        raise tests_failed[profile_url][0] 
      end
      if test_passed
        messages.clear()
      end
    end
  end
end