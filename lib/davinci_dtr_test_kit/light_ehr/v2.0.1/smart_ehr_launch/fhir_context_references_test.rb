module DaVinciDTRTestKit
  class FhirContextReferencesTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    id :fhir_context_references
    title 'fhirContext Request, QuestionnaireResponse, or Task References Test'
    description %(
      This test validates that when the light EHR launches a DTR SMART App, the launch context includes
      a `fhirContext` with exactly one of the following references and that the referenced resource can be read from
      the light DTR EHR:
      - A CRD-type Request or Encounter resource
      - An existing incomplete QuestionnaireResponse previously created with DTR
      - A Questionnaire Task

      See the [Launching DTR](https://hl7.org/fhir/us/davinci-dtr/STU2/specification.html#launching-dtr)
      section of the DTR IG for details.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@127', 'hl7.fhir.us.davinci-dtr_2.0.1@128',
                          'hl7.fhir.us.davinci-dtr_2.0.1@129'
    optional

    uses_request :token

    fhir_client do
      url :url
      bearer_token JSON.parse(request.response_body)['access_token']
    end

    def scratch_resources
      scratch[:crd_request_resources] ||= {}
    end

    run do
      token_response_params = JSON.parse(request.response_body)

      skip_if(!token_response_params['fhirContext'].present?,
              %(fhirContext not present on the passed launch context, skipping test.))

      context_reference = token_response_params['fhirContext'].filter do |c|
        ['DeviceRequest', 'ServiceRequest', 'CommunicationRequest', 'MedicationRequest', 'Encounter', 'Task',
         'QuestionnaireResponse'].include?(c.split('/')[0])
      end

      assert context_reference.present?,
             'fhirContext does not contain a CRD-type request, QuestionnaireResponse, or Task resource'

      context_reference_amount = context_reference.length
      assert context_reference_amount == 1,
             'fhirContext should only contain one CRD-type request, QuestionnaireResponse, or Task'

      crd_request_array = [context_reference[0].split('/')[1]]
      assert crd_request_array.present?,
             'fhirContext does not contain a CRD-type request, QuestionnaireResponse, or Task resource in proper format'

      perform_read_test(crd_request_array, context_reference[0].split('/')[0])
    end
  end
end
