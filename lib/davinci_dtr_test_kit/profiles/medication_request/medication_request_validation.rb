module DaVinciDTRTestKit
  class MedicationRequestValidationTest < Inferno::Test
    include USCoreTestKit::ValidationTest

    title 'MedicationRequest resources returned during previous tests conform to the CRD MedicationRequest'
    description %(
This test verifies resources returned from the read step conform to
the [CRD MedicationRequest](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-medicationrequest).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :medication_request_validation

    def resource_type
      'MedicationRequest'
    end

    def scratch_resources
      scratch[:medication_requests] ||= {}
    end

    run do
      perform_validation_test(scratch_resources[:all] || [],
                              'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-medicationrequest',
                              '2.0.1',
                              skip_if_empty: true)
    end
  end
end
