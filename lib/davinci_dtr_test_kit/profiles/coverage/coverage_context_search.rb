require_relative '../../search_test'
require_relative '../../group_metadata'

module DaVinciDTRTestKit
  class CoverageContextSearchTest < Inferno::Test
    include DaVinciDTRTestKit::SearchTest

    title 'Server returns valid results for Coverage search by context'
    description %(
A server SHALL support searching by
context on the Coverage resource. This test
will pass if resources are returned and match the search criteria. If
none are returned, the test is skipped.

[US Core Server CapabilityStatement](http://hl7.org/fhir/us/core/STU3.1.1/CapabilityStatement-us-core-server.html)

      )

    id :coverage_context_search
    optional

    def self.properties
      @properties ||= SearchTestProperties.new(
        resource_type: 'Coverage',
        search_param_names: ['context']
      )
    end

    def self.metadata
      @metadata ||= Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'), aliases: true))
    end

    def scratch_resources
      scratch[:coverage_resources] ||= {}
    end

    run do
      run_search_test
    end
  end
end
