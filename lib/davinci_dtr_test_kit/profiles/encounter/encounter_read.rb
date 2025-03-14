require_relative '../../read_test'

module DaVinciDTRTestKit
  class EncounterReadTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    title 'Server returns correct Encounter resource from Encounter read interaction'
    description 'A server SHOULD support the Encounter read interaction.'
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@271'

    id :encounter_read
    output :encounter_resources

    def resource_type
      'Encounter'
    end

    def scratch_resources
      scratch[:encounters] ||= {}
    end

    def encounter_id_list
      return [nil] unless respond_to? :encounter_ids

      encounter_ids&.split(',')&.map(&:strip)
    end

    run do
      perform_read_test(encounter_id_list, resource_type)
    end
  end
end
