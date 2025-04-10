require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormResponseBundlesTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_bundles_validation_test
    title 'Validate that the adaptive response contains valid Questionnaire Bundle resources'
    description %(
      This test ensures that the payer's response includes a resource that conforms to the the
      [DTR Questionnaire Bundle](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@303'

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      test_passed = true
      profile_url = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle|2.0.1'
      assert scratch[:adaptive_questionnaire_bundles].present?, 'No resources to validate.'
      scratch[:adaptive_questionnaire_bundles].each_with_index do |bundle, index|
        resource_is_valid = validate_resource(bundle, :bundle, profile_url, index)
        test_passed = false unless resource_is_valid
      rescue StandardError
        next
      end
      if !test_passed && !tests_failed[profile_url].blank?
        assert test_passed, "Not all returned resources conform to the profile: #{profile_url}"
      end
    end
  end
end
