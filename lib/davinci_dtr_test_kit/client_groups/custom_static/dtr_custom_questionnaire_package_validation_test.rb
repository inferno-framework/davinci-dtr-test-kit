require_relative '../../cql_test'
module DaVinciDTRTestKit
  class DTRCustomQuestionnairePackageValidationTest < Inferno::Test
    include DaVinciDTRTestKit::CQLTest

    id :dtr_custom_qp_validation
    title '[USER INPUT VERIFICATION] Custom Questionnaire Package response is valid'
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
          type: 'textarea'

    def form_type
      config.options[:form_type] || 'static'
    end

    run do
      assert_valid_json custom_questionnaire_package_response, 'Custom questionnaire package response is not valid JSON'

      resource = FHIR.from_contents(custom_questionnaire_package_response)

      perform_questionnaire_package_validation(resource, form_type)
    end
  end
end
