module DaVinciDTRTestKit
  class NutritionOrderMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the NutritionOrder resources returned'
    description %(
      This test will look through the NutritionOrder resources
      found previously for the following must support elements:\n

      * NutritionOrder.allergyIntolerance
      * NutritionOrder.dateTime
      * NutritionOrder.encounter
      * NutritionOrder.enteralFormula
      * NutritionOrder.excludeFoodModifier
      * NutritionOrder.extension:Coverage-Information
      * NutritionOrder.foodPreferenceModifier
      * NutritionOrder.identifier
      * NutritionOrder.oralDiet
      * NutritionOrder.orderer
      * NutritionOrder.patient
      * NutritionOrder.status
      * NutritionOrder.supplement
    )
    id :nutrition_order_must_support_test

    def resource_type
      'NutritionOrder'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:nutrition_orders] ||= {}
    end

    run do
      skip_if(nutrition_order_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
