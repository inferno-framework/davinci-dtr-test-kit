require_relative 'service_request/service_request_read'
require_relative 'service_request/service_request_validation'

module DaVinciDTRTestKit
  class ServiceRequestGroup < Inferno::TestGroup
    title 'CRD ServiceRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD ServiceRequest Profile'
    description %(
      # Background

    The CRD ServiceRequest sequence verifies that the system under test is
    able to provide correct responses for ServiceRequest queries. These queries
    must return resources conforming to the [CRD ServiceRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-servicerequest)
    as specified in the DaVinci Coverage Requirements Discovery (CRD) v2.0.1
    Implementation Guide.

    # Testing Methodology
    ## Read
    This test sequence will first perform the required read associated
    with this resource. The server SHOULD be capable of returning a
    ServiceRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the first read is expected to conform to
    the [CRD ServiceRequest Profile](http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-servicerequest).
    Each element is checked against terminology binding and cardinality requirements.

    )
    id :service_request_group
    run_as_group

    input :service_request_ids

    test from: :service_request_read
    test from: :service_request_validation
  end
end
