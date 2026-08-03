require_relative '../../../tags'
require_relative '../../../urls'
require_relative '../../validation_test'
require_relative '../../../cross_suite/v2.2.0/questionnaire_operation_validation'

module DaVinciDTRTestKit
  module DTRPayerServerV220
    class QuestionnaireResponseValidationTest < Inferno::Test
      include URLs
      include DaVinciDTRTestKit::ValidationTest
      include QuestionnaireOperationValidation

      id :dtr_v220_payer_questionnaire_response_validation
      # TODO: this is all placeholder just to demonstrate what the basic
      #       response validation will look like

      title 'Validate that the response conforms to the DTR Questionnaire Package operation definition.'
      description %(
        Inferno will validate that the payer server's response to the
        questionnaire-package operation is conformant to the [Questionnaire
        Package operation
        definition](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-questionnaire-package.html).
        This includes verifying that the response conforms to the [DTR
        Questionnaire Package Bundle
        profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-DTR-QPackageBundle.html)
        and, in the event that the server includes that Bundle in a Parameters
        object, the [DTR Questionnaire Package Output Parameters
        profile](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-qpackage-output-parameters.html).

        It verifies the presence of mandatory elements and that elements with
        required bindings contain appropriate values. CodeableConcept element
        bindings will fail if none of their codings have a code/system belonging
        to the bound ValueSet. Quantity, Coding, and code element bindings will
        fail if their code/system are not found in the valueset.
      )
      verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@oper-10'
      input :url

      run do
        load_tagged_requests(QUESTIONNAIRE_TAG)

        skip_if requests.blank?, 'No $questionnaire-package requests were made'

        requests.each do |request|
          assert_response_status([200, 201], response: request.response)

          resource = FHIR.from_contents(request.response_body)

          # NOTE: This interface is not finalized
          perform_questionnaire_package_validation(resource)
        end
      end
    end
  end
end
