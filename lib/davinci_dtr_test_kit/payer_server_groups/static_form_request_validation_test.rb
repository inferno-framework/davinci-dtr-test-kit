require_relative '../urls'
require_relative '../validation_test'
module DaVinciDTRTestKit
  class PayerStaticFormRequestValidationTest < Inferno::Test
    include DaVinciDTRTestKit::ValidationTest
    include URLs

    id :dtr_v201_payer_static_form_request_validation_test
    title 'User Input Validation:  Client sends payer server a request for a static form'
    description %(
      Inferno will validate that the request to the payer server conforms to the
       [Input Parameters profile](http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters).

       It verifies the presence of mandatory elements and that elements with required bindings contain appropriate
       values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
       to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system
       are not found in the valueset.
    )
    input :initial_static_questionnaire_request, :access_token, :retrieval_method

    run do
      skip_if retrieval_method == 'Adaptive', 'Performing only adaptive flow tests - only one flow is required.'

      profile_with_version = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-qpackage-input-parameters|2.0.1'

      if initial_static_questionnaire_request.nil?
        skip_if access_token.nil?, 'No access token provided - required for client flow.'
        requests = load_tagged_requests(QUESTIONNAIRE_TAG)
        skip_if requests.blank?, 'No request resource received from the client.'
        # making the assumption that only one request was made here - if there were multiple, we are only validating the
        # first
        resource_is_valid?(resource: FHIR.from_contents(requests[0].request[:body]), profile_url: profile_with_version)
      else
        request = FHIR.from_contents(initial_static_questionnaire_request)
        resource_is_valid?(resource: request, profile_url: profile_with_version)
      end

      # TODO FIXME
      # binding.pry

      errors_found = messages.any? { |message| message[:type] == 'error' }
      skip_if errors_found, "Resource does not conform to the profile #{profile_with_version}"
    end
  end
end
