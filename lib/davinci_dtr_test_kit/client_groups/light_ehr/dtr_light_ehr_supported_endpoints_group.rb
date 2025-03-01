require_relative 'dtr_light_ehr_supported_payers_accept_header_test'
require_relative 'dtr_light_ehr_supported_payers_endpoint_test'
require_relative 'dtr_light_ehr_supported_payers_user_response_test'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedEndpointsGroup < Inferno::TestGroup
    id :dtr_light_ehr_supported_endpoints
    title 'Supported Endpoints'
    description %(This test group tests system for their conformance to
      the supported endpoint capabilities as defined by the DaVinci Documentation
      Templates and Rules [DTR v2.0.1 Implementation Guide Light DTR EHR
      Capability Statement](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#determination-of-payers-supported-by-a-dtr-app).

      )
    run_as_group

    test from: :dtr_light_ehr_sp_endpoint
    test from: :dtr_light_ehr_sp_accept_header
    test from: :dtr_light_ehr_sp_user_response
  end
end
