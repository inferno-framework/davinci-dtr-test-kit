require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_next_response_validation_test
    title 'Inferno sends payer server a request for subsequent adaptive forms - validate the responses'
    output :questionnaire_bundle

    run do
      resources = load_tagged_requests(NEXT_TAG)
      perform_response_validation_test(
        resources,
        :questionnaireResponse,
        'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse')
    end
  end
end