module DaVinciDTRTestKit
  class EncounterMustSupportTEst < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the Encounter resources returned'
    description %(
      This test will look through the Encounter resources
      found previously for the following must support elements:\n

      * Encounter.appointment
      * Encounter.class
      * Encounter.diagnosis
      * Encounter.diagnosis.condition
      * Encounter.extension:Coverage-Information
      * Encounter.hospitalization
      * Encounter.hospitalization.dischargeDisposition
      * Encounter.identifier
      * Encounter.identifier.system
      * Encounter.identifier.value
      * Encounter.length
      * Encounter.location
      * Encounter.location.location
      * Encounter.location.period
      * Encounter.location.status
      * Encounter.participant
      * Encounter.participant.individual
      * Encounter.participant.period
      * Encounter.participant.type
      * Encounter.period
      * Encounter.reasonCode
      * Encounter.reasonReference
      * Encounter.serviceType
      * Encounter.status
      * Encounter.subject
      * Encounter.type
    )
    id :encounter_must_support_test

    def resource_type
      'Encounter'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:encounters] ||= {}
    end

    run do
      skip_if(encounter_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
