require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRQuestionnairePackageValidationTest < Inferno::Test
    include URLs

    id :dtr_questionnaire_package_request_validation
    title 'Questionnaire Package request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Questionnaire Package Input Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )

    run do
      load_tagged_requests QUESTIONNAIRE_PACKAGE_TAG
      assert request.url == questionnaire_package_url,
             "Request made to wrong URL: #{request.url}. Should instead be to #{questionnaire_package_url}"

      assert_valid_json(request.request_body)
      input_params = FHIR.from_contents(request.request_body)
      assert input_params.present?, 'Request does not contain a recognized FHIR object'
      assert_resource_type(:parameters, resource: input_params)
      assert_valid_resource(resource: input_params,
                            profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters')
    end
  end
end
