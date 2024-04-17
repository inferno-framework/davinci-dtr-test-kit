require_relative '../validation_test'
module DaVinciDTRTestKit
  class AdaptiveQuestionnairePackageValidationTest < Inferno::Test
    include URLs
    include DaVinciDTRTestKit::ValidationTest
    title '[USER INPUT VALIDATION] Questionnaire Package request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Questionnaire Package Input Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )
    id :payer_server_adaptive_questionnaire_request_validation

    run do
      resources = load_tagged_requests(QUESTIONNAIRE_TAG)
      perform_request_validation_test(
      resources,
      :parameters,
      'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters',
      questionnaire_package_url)

      validation_error_messages.each do |msg|
        messages << { type: 'error', message: msg }
      end
      msg = 'Bundle(s) provided and/or entry resources are not conformant. Check messages for issues found.'
      skip_if validation_error_messages.present?, msg

    end
  end
end
