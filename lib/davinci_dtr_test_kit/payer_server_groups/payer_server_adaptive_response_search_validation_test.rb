require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormResponseSearchTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_search_validation_test
    title 'Validate that the adaptive response contains valid a Adaptive Form Search resource'
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
      test_passed = true
      profile_url = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaire-adapt-search'
      assert !scratch[:adaptive_responses].nil?, 'No resources to validate.'
      scratch[:adaptive_responses].each_with_index do |resource, index|
        fhir_resource = FHIR.from_contents(resource.response[:body])
        fhir_resource.parameter.each do |param|
          param.resource.entry.each do |entry|
            resource_is_valid = validate_resource(entry.resource, :questionnaire, profile_url, index)
            test_passed = false unless resource_is_valid
          end
        rescue StandardError
          next
        end
      end
      if !test_passed && !tests_failed[profile_url].blank?
        raise assert test_passed,
                     "Not all returned resources conform to the profile: #{profile_url}"
      end
    end
  end
end
