require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_next_response_validation_test
    title 'Inferno sends payer server a request for subsequent adaptive forms - validate the responses'
    output :questionnaire_bundle

    run do

      perform_response_validation_test(
        NEXT_TAG,
        :parameters,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end