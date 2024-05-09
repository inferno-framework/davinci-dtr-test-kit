module DaVinciDTRTestKit
  class PayerStaticFormTest < Inferno::Test
    id :dtr_v201_payer_static_form_test
    title 'Client sends payer server a request for a static form'
    # output :questionnaire_bundle

    run do

      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      resource_instance = FHIR.from_contents(initial_questionnaire_request)
      # assert_valid_resource(resource: resource_instance, profile_url: "http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters")
      fhir_operation("#{url}/Questionnaire/$questionnaire-package/", body: JSON.parse(initial_questionnaire_request), headers: {"Content-Type": "application/json"})
      scratch[:questionnaire_bundle] = resource

      assert_response_status(200)
      assert_resource_type(:parameters)
      assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')

      
    end
  end
end
