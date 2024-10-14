require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormRequestTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    title 'User Input Validation: Questionnaire Package request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Questionnaire Package Input Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )
    id :payer_server_adaptive_questionnaire_request_validation

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      profile_with_version = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1'
      if initial_adaptive_questionnaire_request.nil?
        requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.blank?, 'No request resource received from the client.'
        # making the assumption that only one request was made here - if there were multiple, we are only validating the
        # first
        resource_is_valid?(resource: FHIR.from_contents(requests[0].request[:body]), profile_url: profile_with_version)
      else
        request = FHIR.from_contents(initial_adaptive_questionnaire_request)
        resource_is_valid?(resource: request, profile_url: profile_with_version)
      end
      errors_found = messages.any? { |message| message[:type] == 'error' }
      skip_if errors_found, "Resource does not conform to the profile #{profile_with_version}"
    end
  end
end
