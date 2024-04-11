require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_validation_test
    title 'Inferno sends payer server a request for an adaptive form - validate the response'
    output :questionnaire_bundle

    run do

      perform_response_validation_test(
        QUESTIONNAIRE_TAG,
        :parameters,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end