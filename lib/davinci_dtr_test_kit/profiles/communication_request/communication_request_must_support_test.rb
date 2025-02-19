module DaVinciDTRTestKit
  class CommunicationRequestMustSupportTest < Inferno::Test
    include USCoreTestKit::MustSupportTest

    title 'All must support elements are provided in the CommunicationRequest resources returned'
    description %(
      This test will look through the CommunicationRequest resources
      found previously for the following must support elements:\n

      * CommunicationRequest.authoredOn
      * CommunicationRequest.basedOn
      * CommunicationRequest.extension:Coverage-Information
      * CommunicationRequest.identifier
      * CommunicationRequest.occurrence[x]
      * CommunicationRequest.payload
      * CommunicationRequest.payload.extension:codeableConcept
      * CommunicationRequest.reasonCode
      * CommunicationRequest.reasonReference
      * CommunicationRequest.recipient
      * CommunicationRequest.requester
      * CommunicationRequest.sender
      * CommunicationRequest.status
      * CommunicationRequest.subject
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@355'
    id :communication_request_must_support_test

    def resource_type
      'CommunicationRequest'
    end

    def self.metadata
      @metadata ||= USCoreTestKit::Generator::GroupMetadata.new(YAML.load_file(File.join(__dir__, 'metadata.yml'),
                                                                               aliases: true))
    end

    def scratch_resources
      scratch[:communication_requests] ||= {}
    end

    run do
      skip_if(communication_request_ids.nil?, "No `#{resource_type}` IDs provided, skipping test.")
      perform_must_support_test(all_scratch_resources)
    end
  end
end
