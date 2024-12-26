require_relative 'dtr_light_ehr_supported_payer_endpoint_test'

module DaVinciDTRTestKit
  class DTRLightEhrSupportedEndpointsGroup < Inferno::TestGroup
    id :dtr_light_ehr_supported_endpoints
    title 'Supported Endpoints'
    description %(This test group tests system for their conformance to
      the supported endpoint capabilities as defined by the DaVinci Documentation
      Templates and Rules (DTR) v2.0.1 Implementation Guide Light DTR EHR
      Capability Statement.

      )
    run_as_group

    test from: :dtr_light_ehr_supported_payer_endpoint
  end
end
