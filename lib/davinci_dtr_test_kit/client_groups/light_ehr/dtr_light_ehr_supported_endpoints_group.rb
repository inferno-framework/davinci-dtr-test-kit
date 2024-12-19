require_relative 'dtr_light_ehr_supported_payer_endpoint_test'

module DaVinciDTRTestKit
  class DTRLightEhrSupportedEndpointsGroup < Inferno::TestGroup
    id :dtr_light_ehr_supported_endpoints
    title 'DTR Supported Endpoints'
    description %(
      Demonstrate the ability to access supported endpoints
    )
    run_as_group

    test from: :dtr_light_ehr_supported_payer_endpoint
  end
end
