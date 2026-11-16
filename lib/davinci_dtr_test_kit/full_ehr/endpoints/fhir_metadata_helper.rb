require_relative '../../version'

module DaVinciDTRTestKit
  module MockPayer
    module FHIRMetadataHelper
      module_function

      def get_metadata(version)
        erb_template = ERB.new(
          File.read(
            File.join(__dir__, "metadata/capability_statement_#{version}.json.erb")
          )
        )
        capability_statement = JSON.parse(erb_template.result(binding)).to_json

        proc {
          [200, { 'Content-Type' => 'application/fhir+json;charset=utf-8', 'Access-Control-Allow-Origin' => '*' },
           [capability_statement]]
        }
      end
    end
  end
end
