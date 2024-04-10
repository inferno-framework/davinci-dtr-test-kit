
module DaVinciDTRTestKit
  class PayerAdaptiveFormTest < Inferno::Test

    id :payer_server_adaptive_response_validation_test
    title 'Inferno sends payer server a request for an adaptive form'
    output :questionnaire_bundle

    run do

      # fhir_operation("#{url}/Questionnaire/HomeOxygenTherapyAdditional/$questionnaire-package/", body: JSON.parse(request.request_body), headers: {"Content-Type": "application/json"})

      assert_response_status(200)
      assert_resource_type(:parameters)
      assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end