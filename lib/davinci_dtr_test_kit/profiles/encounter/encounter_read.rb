require_relative '../../read_test'

module DaVinciDTRTestKit
  class EncounterReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct Encounter resource from Encounter read interaction'
    description 'A server SHOULD support the Encounter read interaction.'

    id :encounter_read
    optional
    output :encounter_resources

    def resource_type
      'Encounter'
    end

    def encounter_id_list
      return [nil] unless respond_to? :encounter_ids

      encounter_ids&.split(',')&.map(&:strip)
    end

    run do
      resources = perform_read_test(encounter_id_list, resource_type)

      output encounter_resources: resources.to_json
    end
  end
end
