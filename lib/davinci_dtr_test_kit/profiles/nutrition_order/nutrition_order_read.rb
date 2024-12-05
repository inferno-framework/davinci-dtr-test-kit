require_relative '../../read_test'

module DaVinciDTRTestKit
  class NutritionOrderReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct NutritionOrder resource from NutritionOrder read interaction'
    description 'A server SHOULD support the NutritionOrder read interaction.'

    id :nutrition_order_read
    optional
    output :nutrition_order_resources

    def resource_type
      'NutritionOrder'
    end

    def nutrition_order_id_list
      return [nil] unless respond_to? :nutrition_order_ids

      nutrition_order_ids&.split(',')&.map(&:strip)
    end

    run do
      resources = perform_read_test(nutrition_order_id_list, resource_type)

      output nutrition_order_resources: resources.to_json
    end
  end
end
