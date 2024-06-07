require_relative '../urls'
require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerStaticFormResponseTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    id :dtr_v201_payer_static_form_response_test
    title 'Validate that the static response conforms to the Output Parameters profile'
    description %(
      Inferno will validate that the payer server response conforms to the 
       [Output Parameters profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters).

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
        skip_if access_token.nil?, 'No access token provided - required for client flow.'
        resources = load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if resources.nil?, 'No request resource received from the client.'
        scratch[:questionnaire_bundle] = resources
        perform_response_validation_test(
          resources,
          :parameters,
          'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters'
        )
      else
        FHIR.from_contents(initial_static_questionnaire_request)
        fhir_operation("#{url}/Questionnaire/$questionnaire-package", body: JSON.parse(initial_static_questionnaire_request),
                                                                      headers: { 'Content-Type': 'application/json' })
        scratch[:questionnaire_bundle] = resource

        assert_response_status(200)
        assert_resource_type(:parameters)
        questionnaire_bundle = resource.parameter.find { |param| param.name == 'return' }&.resource
        assert questionnaire_bundle, 'No questionnaire bundle found in the response'
        assert_valid_resource(resource: questionnaire_bundle, profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle')
      end
    end
  end
end
