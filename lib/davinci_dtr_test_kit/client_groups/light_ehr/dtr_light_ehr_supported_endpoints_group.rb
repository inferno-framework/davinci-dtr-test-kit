require_relative 'dtr_light_ehr_supported_payers_accept_header_test'
require_relative 'dtr_light_ehr_supported_payers_endpoint_test'
require_relative 'dtr_light_ehr_supported_payers_user_response_test'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedEndpointsGroup < Inferno::TestGroup
    id :dtr_light_ehr_supported_endpoints
    title 'Supported Payers Endpoint'
    description %(This group checks that systems can request and react to a DTR
      SMART App's [list of supported payers](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#determination-of-payers-supported-by-a-dtr-app).
    )
    run_as_group

    test from: :dtr_light_ehr_sp_endpoint
    test from: :dtr_light_ehr_sp_accept_header
    test from: :dtr_light_ehr_sp_user_response
  end
end
