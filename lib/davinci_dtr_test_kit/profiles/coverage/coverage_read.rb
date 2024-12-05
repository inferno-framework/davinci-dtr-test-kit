require_relative '../../read_test'

module DaVinciDTRTestKit
  class CoverageReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct Coverage resource from Coverage read interaction'
    description 'A server SHALL support the Coverage read interaction.'

    id :coverage_read
    output :coverage_resources

    def resource_type
      'Coverage'
    end

    def coverage_id_list
      return [nil] unless respond_to? :coverage_ids

      coverage_ids&.split(',')&.map(&:strip)
    end

    run do
      resources = perform_read_test(coverage_id_list, resource_type)

      output coverage_resources: resources.to_json
    end
  end
end
