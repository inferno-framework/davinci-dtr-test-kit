
module DaVinciDTRTestKit
  class PayerAdaptiveFormNextTest < Inferno::Test

    id :payer_server_next_response_validation_test
    title 'Inferno sends payer server a request for subsequent adaptive forms - validate the responses'
    output :questionnaire_bundle

    run do
      resources = load_tagged_requests(NEXT_TAG)

      resources.each do |resource|
        output_params = FHIR.from_contents(resource.response[:body])
        assert output_params.present?, 'Response does not contain a recognized FHIR object'
        assert_response_status(200, request: resource, response: resource.response)
        assert_resource_type(:parameters, resource: output_params)
        assert_valid_resource(resource: output_params,
                              profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')
        # assert_valid_resource(resource: output_params,
        #                       profile_url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaireresponse-adapt')
      end

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end