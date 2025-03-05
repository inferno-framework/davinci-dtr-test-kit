require_relative '../urls'
require_relative '../validation_test'
require_relative '../cql_test'
module DaVinciDTRTestKit
  class PayerStaticFormResponseTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    include DaVinciDTRTestKit::CQLTest
    id :dtr_v201_payer_static_form_response_test
    title 'Validate that the static response conforms to the DTR Questionnaire Package operation definition.'
    description %(
      Inferno will validate that the payer server's response to the questionnaire-package operation is conformant
      to the
      [Questionnaire Package operation definition](https://hl7.org/fhir/us/davinci-dtr/STU2/OperationDefinition-questionnaire-package.html).
      This includes verifying that the response conforms to the
      [DTR Questionnaire Package Bundle profile](https://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-DTR-QPackageBundle.html)
      and, in the event that the server includes that Bundle in a Parameters object, the
      [DTR Questionnaire Package Output Parameters profile](https://hl7.org/fhir/us/davinci-dtr/STU2/StructureDefinition-dtr-qpackage-output-parameters.html).

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.0.1@169', 'hl7.fhir.us.davinci-dtr_2.0.1@294',
                          'hl7.fhir.us.davinci-dtr_2.0.1@303', 'hl7.fhir.us.davinci-dtr_2.0.1@305',
                          'hl7.fhir.us.davinci-dtr_2.0.1@306'
    input :url

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'
      req = if initial_static_questionnaire_request.nil?
              load_tagged_requests(QUESTIONNAIRE_TAG)
            else
              fhir_operation("#{url}/Questionnaire/$questionnaire-package",
                             body: JSON.parse(initial_static_questionnaire_request),
                             headers: { 'Content-Type': 'application/fhir+json' })
            end

      skip_if req.nil?, 'No request resource received from the client.'
      assert_response_status([200, 201], response: req.response)

      resource = FHIR.from_contents(req.response_body)

      perform_questionnaire_package_validation(resource, 'static')
    end
  end
end
