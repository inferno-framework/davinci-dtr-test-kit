require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_validation_test
    title 'Inferno sends payer server a request for an adaptive form - validate the response'
    output :questionnaire_bundle
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
      resources = load_tagged_requests(QUESTIONNAIRE_TAG)
      perform_response_validation_test(
        resources,
        :parameters,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')
    end
  end
end