require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerAdaptiveFormQuestionnaireResponseTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    id :payer_server_adaptive_response_validation_test
    title 'Validate that the adaptive response conforms to the Output Parameters profile'
    # output :questionnaire_response
    description %(
      This test validates the conformance of the payer's response to the
      [DTR Output Parameters](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters)
      structure.

      It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test may process multiple resources, labeling messages with the corresponding tested resources
      in the order that they were received.
    )

    run do
      skip_if retrieval_method == 'Static', 'Performing only static flow tests - only one flow is required.'
      skip_if access_token.nil? && initial_questionnaire_request.nil?, 'No access token or request resource provided.'
      endpoint = adaptive_endpoint.blank? ? '/Questionnaire/$questionnaire-package' : adaptive_endpoint
      unless initial_questionnaire_request.nil?
        resources = []
        if initial_questionnaire_request.kind_of?(Array)
          initial_questionnaire_request.each { |resource| 
            resources.push(fhir_operation("#{url}#{endpoint}", body: JSON.parse(initial_questionnaire_request), headers: {"Content-Type": "application/json"}))
          }
        else 
          resources.push(fhir_operation("#{url}#{endpoint}", body: JSON.parse(initial_questionnaire_request), headers: {"Content-Type": "application/json"}))
        end
      end
      scratch[:adaptive_responses] =  resources
      perform_response_validation_test(
        resources,
        :parameters,
        'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-output-parameters'
      )
    end
  end
end
