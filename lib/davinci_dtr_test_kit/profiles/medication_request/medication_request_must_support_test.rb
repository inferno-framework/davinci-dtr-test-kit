module DaVinciDTRTestKit
  class MedicationRequestMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the MedicationRequest resources returned'
    description %(
      This test will look through the MedicationRequest resources
      found previously for the following must support elements:\n

      * MedicationRequest.authoredOn
      * MedicationRequest.dispenseRequest
      * MedicationRequest.dosageInstruction
      * MedicationRequest.dosageInstruction.text
      * MedicationRequest.encounter
      * MedicationRequest.extension:Coverage-Information
      * MedicationRequest.identifier
      * MedicationRequest.intent
      * MedicationRequest.medication[x]
      * MedicationRequest.performer
      * MedicationRequest.priorPrescription
      * MedicationRequest.reasonCode
      * MedicationRequest.reasonReference
      * MedicationRequest.reported[x]
      * MedicationRequest.requester
      * MedicationRequest.status
      * MedicationRequest.subject
      * MedicationRequest.substitution
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@354'
    id :medication_request_must_support_test

    def resource_type
      'MedicationRequest'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:medication_requests] ||= {}
    end

    run do
      skip_if(medication_request_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
