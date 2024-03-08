
module DaVinciDTRTestKit
  class PayerStaticFormTest < Inferno::Test

    id :dtr_v201_payer_static_form_test
    title 'Client sends payer server a request for a static form'
    output :questionnaire_bundle

    run do
      assert_valid_resource(resource: questionnaire_parameters, profile_url: "http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters")
      fhir_operation("#{url}/Questionnaire/HomeOxygenTherapyAdditional/$questionnaire-package/", body: JSON.parse(questionnaire_parameters), headers: {"Content-Type": "application/json"})

      assert_response_status(200)
      assert_resource_type(:parameters)
      assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end