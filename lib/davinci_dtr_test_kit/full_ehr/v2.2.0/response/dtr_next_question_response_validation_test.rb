require_relative '../../../urls'
require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220NextQuestionResponseValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_nq_response_validation
    title 'Next Question responses are valid'
    description %(
      This test validates the conformance of the Inferno's simulated response to the
      output of the [DTR Next Question Operation](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/OperationDefinition-DTR-Questionnaire-next-question.html).
      Because there is a single out parameter named "return" and its type is a FHIR QuestionnaireResponse resource,
      the [Parameters format is not used](https://www.hl7.org/fhir/R4/operations.html#response)
      and the response is expected to be a raw QuestionnaireResponse conforming to the
      [DTR Questionnaire Response for adaptive form](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html)
      profile.

      The test verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.
    )
    simulation_verification

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])
      check_for_adaptive_short_circuit

      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'A Next Question request must be made prior to running this test'

      requests.each_with_index do |nq_request, request_index|
        unless nq_request.url == next_url
          add_request_message(
            'error',
            "Request made to wrong URL: #{nq_request.url}. Should instead be to #{next_url}.",
            request_index
          )
        end

        response_body = parse_fhir_request_entity(nq_request.response_body, 'Response', request_index)
        unless response_body.present?
          add_request_message(
            'error',
            'Response does not contain a recognized FHIR resource',
            request_index
          )
          next
        end

        questionnaire_response = questionnaire_response_from_next_question_response(response_body)
        if questionnaire_response.present?
          resource_is_valid?(resource: questionnaire_response,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0',
                             message_prefix: request_prefix(request_index))
        else
          add_request_message(
            'error',
            'Response does not contain a QuestionnaireResponse',
            request_index
          )
        end
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $next-question response(s). See Messages for details."
      )
    end
  end
end
