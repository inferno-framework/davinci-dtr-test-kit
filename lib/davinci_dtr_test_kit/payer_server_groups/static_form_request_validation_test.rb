require_relative '../urls'
require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerStaticFormRequestValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    include URLs
    id :dtr_v201_payer_static_form_request_validation_test
    title '[USER INPUT VALIDATION] Client sends payer server a request for a static form'
    description %(
      Inferno will validate that the request to the payer server conforms to the
       [Input Parameters profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters).

       It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
       values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
       to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
       the valueset.

       This test may process multiple resources, labeling messages with the corresponding tested resources
       in the order that they were received.
    )

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      if initial_static_questionnaire_request.nil?
        using_manual_entry = false
        skip_if access_token.nil?, 'No access token provided - required for client flow.'
        resources = load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if resources.nil?, 'No request resource received from the client.'
        perform_request_validation_test(
          resources,
          :parameters,
          'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters',
          questionnaire_package_url,
          using_manual_entry
        )
      else
        skip_if initial_static_questionnaire_request.nil?, 'No request resource was provided - required for manual flow'
        request = FHIR.from_contents(initial_static_questionnaire_request)
        assert_valid_resource(resource: request, profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters')
      end
    rescue Inferno::Exceptions::AssertionException => e
      msg = e.message.to_s.strip
      skip msg
    end
  end
end
