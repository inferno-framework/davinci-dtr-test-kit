module DaVinciDTRTestKit
  class NutritionOrderValidationTest < Inferno::Test
    include USCoreTestKit::ValidationTest

    title 'NutritionOrder resources returned during previous tests conform to the CRD NutritionOrder'
    description %(
This test verifies resources returned from the read step conform to
the [CRD NutritionOrder](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-nutritionorder).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    id :nutrition_order_validation

    def resource_type
      'NutritionOrder'
    end

    def scratch_resources
      scratch[:nutrition_order_resources] ||= {}
    end

    run do
      perform_validation_test(scratch_resources[:all] || [],
                              'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-nutritionorder',
                              '2.0.1',
                              skip_if_empty: true)
    end
  end
end
