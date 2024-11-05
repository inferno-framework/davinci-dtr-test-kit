require_relative '../../read_test'

module DaVinciDTRTestKit
  class NutritionOrderReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'NutritionOrder resources returned during previous tests conform to the CRD NutritionOrder'
    description %(
This test verifies resources returned from the first read conform to
the [CRD NutritionOrder](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-nutritionorder).
Systems must demonstrate at least one valid example in order to pass this test.

It verifies the presence of mandatory elements and that elements with
required bindings contain appropriate values. CodeableConcept element
bindings will fail if none of their codings have a code/system belonging
to the bound ValueSet. Quantity, Coding, and code element bindings will
fail if their code/system are not found in the valueset.

    )

    title 'Server returns correct NutritionOrder resource from NutritionOrder read interaction'
    description 'A server SHALL support the NutritionOrder read interaction.'

    id :nutrition_order_read
    output :nutrition_order_resources

    def resource_type
      'NutritionOrder'
    end

    def nutrition_order_id_list
      return [nil] unless respond_to? :nutrition_order_ids

      nutrition_order_ids.split(',').map(&:strip)
    end

    run do
      resources = perform_read_test(nutrition_order_id_list, resource_type)

      output nutrition_order_resources: resources.to_json
    end
  end
end
