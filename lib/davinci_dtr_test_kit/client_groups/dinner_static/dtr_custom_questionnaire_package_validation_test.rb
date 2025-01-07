module DaVinciDTRTestKit
  class DTRCustomQuestionnairePackageValidationTest < Inferno::Test
    id :dtr_custom_questionnaire_package_validation
    title 'Custom Questionnaire Package response is valid'
    description %(
      Inferno will validate that the user provided response to the questionnaire-package operation is conformant
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

    input :custom_questionnaire_package_response,
          title: 'Custom Questionnaire Package Response JSON',
          description: %(
            A JSON PackageBundle may be provided here to replace Inferno's response to the
            $questionnaire-package request.
          ),
          type: 'textarea',
          optional: true

    run do
      omit_if custom_questionnaire_package_response.blank?, 'Custom response was not provided'

      assert_valid_json custom_questionnaire_package_response

      resource = FHIR.from_contents(custom_questionnaire_package_response)
      if resource&.resourceType == 'Parameters'
        scratch[:static_questionnaire_bundles] = resource.parameter&.filter_map do |param|
          param.resource if param.resource&.resourceType == 'Bundle'
        end
        assert_valid_resource(resource:,
                              profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters|2.0.1')
        questionnaire_bundle = resource.parameter.find { |param| param.resource.resourceType == 'Bundle' }&.resource
        assert questionnaire_bundle, 'No questionnaire bundle found in the response'
      elsif resource&.resourceType == 'Bundle'
        scratch[:static_questionnaire_bundles] = [resource]
        assert_valid_resource(resource:,
                              profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/DTR-QPackageBundle|2.0.1')
      else
        assert(false, "Unexpected resourceType: #{resource&.resourceType}. Expected Parameters or Bundle")
      end
    end
  end
end
