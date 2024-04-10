
module DaVinciDTRTestKit
  class PayerAdaptiveFormTest < Inferno::Test

    id :payer_server_adaptive_response_validation_test
    title 'Inferno sends payer server a request for an adaptive form - validate the response'
    output :questionnaire_bundle

    run do

      resources = load_tagged_requests(QUESTIONNAIRE_TAG)

      resources.each do |resource|
        output_params = FHIR.from_contents(resource.response[:body])
        assert output_params.present?, 'Response does not contain a recognized FHIR object'
        assert_response_status(200, request: resource, response: resource.response)
        assert_resource_type(:parameters, resource: output_params)
        assert_valid_resource(resource: output_params,
                              profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters')
      end

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end