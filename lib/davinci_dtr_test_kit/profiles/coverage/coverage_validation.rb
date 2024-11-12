require_relative '../../validation_test'

module DaVinciDTRTestKit
  class CoverageValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest

    title 'Coverage resources returned during previous tests conform to the CRD Coverage'
    description %(
This test verifies resources returned from the first read conform to
the [CRD Coverage](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-coverage).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :coverage_validation
    input :coverage_resources

    def resource_type
      'Coverage'
    end

    run do
      perform_request_validation_test(coverage_resources, resource_type,
                                      'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-coverage',
                                      '2.0.1', true)
    end
  end
end
