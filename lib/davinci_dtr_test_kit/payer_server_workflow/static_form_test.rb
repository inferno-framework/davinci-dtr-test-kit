
module DaVinciDTRTestKit
  class PayerStaticFormTest < Inferno::Test

    id :dtr_v201_payer_static_form_test
    title 'Client sends payer server a request for a static form'
    output :questionnaire_bundle

    run do
      request_params = FHIR::Parameters.new(
        parameter: [
          {
            name: 'order',
            resource: {
              resourceType: "ServiceRequest",
              id: "ServiceRequestExample",
              meta: {
                profile: [
                  "http://hl7.org/fhir/us/davinci-crd/StructureDefinition/profile-servicerequest"
                ]
              },
              status: "draft",
              intent: "original-order",
              code: {
                coding: [
                  {
                    system: "http://loinc.org",
                    code: "24338-6"
                  }
                ],
                text: "Gas panel - Blood"
              },
              subject: {
                reference: "Patient/examplepatient"
              },
              occurrenceDateTime: "2019-05-08T09:33:27+07:00",
              authoredOn: "2019-09-18T07:53:21+07:00",
              requester: {
                reference: "Practitioner/PractitionerExample"
              },
              reasonCode: [
                {
                  coding: [
                    {
                      system: "http://snomed.info/sct",
                      code: "4565000"
                    }
                  ],
                  text: "Decreased oxygen affinity"
                }
              ]
            }
          }
        ]
      )
      fhir_operation("#{url}/Questionnaire/$questionnaire-package", body: request_params)

      assert_response_status(200)
      assert_resource_type(:questionnaire_bundle)
      assert_valid_resource(profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle')

      output questionnaire_bundle: questionnaire_bundle
    end
  end
end