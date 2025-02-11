require_relative '../../read_test'

module DaVinciDTRTestKit
  class NutritionOrderReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct NutritionOrder resource from NutritionOrder read interaction'
    description 'A server SHOULD support the NutritionOrder read interaction.'

    id :nutrition_order_read
    output :nutrition_order_resources

    def resource_type
      'NutritionOrder'
    end

    def scratch_resources
      scratch[:nutrition_order_resources] ||= {}
    end

    def nutrition_order_id_list
      return [nil] unless respond_to? :nutrition_order_ids

      nutrition_order_ids&.split(',')&.map(&:strip)
    end

    run do
      perform_read_test(nutrition_order_id_list, resource_type)
    end
  end
end
