require_relative 'service_request/service_request_read'
require_relative 'service_request/service_request_validation'
require_relative 'service_request/service_request_must_support_test'

module DaVinciDTRTestKit
  class ServiceRequestGroup < Inferno::TestGroup
    title 'CRD ServiceRequest Tests'
    short_description 'Verify support for the server capabilities required by the CRD ServiceRequest Profile'
    description %(
      # Background

    The CRD ServiceRequest sequence verifies that the system under test is
    able to provide correct responses for ServiceRequest queries. These queries
    must return resources conforming to the [CRD ServiceRequest Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-servicerequest.html).

    # Testing Methodology
    ## Read
    First, Inferno will attempt to read each ServiceRequest resource id provided in
    the ServiceRequest IDs input. The server SHOULD be capable of returning a
    ServiceRequest resource using the read interaction.

    ## Profile Validation
    Each resource returned from the read step SHALL conform to
    the [CRD ServiceRequest Profile](https://hl7.org/fhir/us/davinci-crd/STU2/StructureDefinition-profile-servicerequest.html).
    Each element is checked against terminology binding and cardinality requirements.

    ## Must Support
    Each profile contains elements marked as "must support". This test
    sequence expects to see each of these elements at least once. If at
    least one cannot be found, the test will fail. The test will look
    through the ServiceRequest resources found in the first test for these
    elements.

    )
    id :service_request_group
    optional
    run_as_group

    input :service_request_ids,
          title: 'Service Request IDs',
          description: 'Comma separated list of ServiceRequest IDs',
          optional: true

    test from: :service_request_read
    test from: :service_request_validation
    test from: :service_request_must_support_test
  end
end
