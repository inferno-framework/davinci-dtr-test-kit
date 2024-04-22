require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_next_response_validation_test
    title 'Inferno sends payer server a request for subsequent adaptive forms - validate the responses'
    output :questionnaire_bundle
    description %(
      This test validates the conformance of the payer's response to the
      [SDC Questionnaire Response](http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources 
      in the order that they were received.
    )

    run do
      resources = load_tagged_requests(NEXT_TAG)
      perform_response_validation_test(
        resources,
        :questionnaireResponse,
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse')
    end
  end
end