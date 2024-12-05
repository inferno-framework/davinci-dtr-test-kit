require_relative '../../validation_test'

module DaVinciDTRTestKit
  class NutritionOrderValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest

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
    optional
    input :nutrition_order_resources,
          optional: true

    def resource_type
      'NutritionOrder'
    end

    run do
      perform_profile_validation_test(nutrition_order_resources, resource_type,
                                      'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-nutritionorder|2.0.1')
    end
  end
end
