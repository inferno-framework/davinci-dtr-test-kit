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
      
      This test may process multiple resources, labeling messages with the corresponding tested resources 
      in the order that they were received.
    )
    id :payer_server_adaptive_questionnaire_request_validation

    run do
      skip_if access_token.nil? && initial_questionnaire_request.nil?, 'No access token or request resource provided.'
      unless initial_questionnaire_request.nil?
        resources = initial_questionnaire_request
      else
        resources = load_tagged_requests(QUESTIONNAIRE_TAG)
      end
      perform_request_validation_test(
      resources,
      :parameters,
      'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters',
      questionnaire_package_url)
    rescue Inferno::Exceptions::AssertionException => e
      msg = "#{e.message}".strip
      skip msg

    end
  end
end
