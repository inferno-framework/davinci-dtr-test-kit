require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormRequestTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    title '[USER INPUT VALIDATION] Questionnaire Package request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Questionnaire Package Input Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.
    )
    id :payer_server_adaptive_questionnaire_request_validation

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      profile_with_version = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1'
      if initial_adaptive_questionnaire_request.nil?
        resources = load_tagged_requests(QUESTIONNAIRE_TAG)
        using_manual_entry = false
      else
        resources = initial_adaptive_questionnaire_request
        using_manual_entry = true
      end
      skip_if resources.nil?, 'No request resources to validate.'
      perform_request_validation_test(
        resources,
        :parameters,
        profile_with_version,
        questionnaire_package_url,
        using_manual_entry
      )
      errors_found = messages.any? { |message| message[:type] == 'error' }
      skip_if errors_found, "Resource does not conform to the profile #{profile_with_version}"
    end
  end
end
