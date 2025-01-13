module DaVinciDTRTestKit
  class FhirContextReferencesTest < Inferno::Test
    include DaVinciDTRTestKit::ReadTest

    id :fhir_context_references
    title 'FHIR Context References Test'

    uses_request :token

    fhir_client do
      url :url
      bearer_token JSON.parse(request.response_body)['access_token']
    end

    run do
      fhir_context = JSON.parse(request.response_body)

      assert fhir_context['fhirContext'].present?

      crd_request = fhir_context['fhirContext'].find do |c|
        c.split('/')[0] == 'DeviceRequest' || c.split('/')[0] == 'ServiceRequest' ||
          c.split('/')[0] == 'CommunicationRequest' || c.split('/')[0] == 'MedicationRequest' ||
          c.split('/')[0] == 'Encounter' || c.split('/')[0] == 'Task' || c.split('/')[0] == 'QuestionnaireResponse'
      end

      assert crd_request.present?

      crd_request_array = [crd_request.split('/')[1]]
      assert crd_request_array.present?

      perform_read_test(crd_request_array, crd_request.split('/')[0])
    end
  end
end
