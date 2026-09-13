require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../cross_suite/v2.2.0/questionnaire_response_completeness'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220NextQuestionRequestValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper
    include QuestionnaireResponseCompleteness
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_nq_request_validation
    title 'Next Question request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Next Question Input Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-next-question-input-parameters.html)
      structure. Because there is only a single in parameter, the request is allowed to be just a
      [DTR Questionnaire Response for adaptive form](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html)
      per [FHIR's operation request requirements](https://www.hl7.org/fhir/R4/operations.html#request).

      The test verifies the presence of mandatory elements and that elements with required bindings contain appropriate
      values. CodeableConcept element bindings will fail if none of their codings have a code/system belonging
      to the bound ValueSet. Quantity, Coding, and code element bindings will fail if their code/system are not found in
      the valueset.

      This test also verifies that the QuestionnaireResponse provided in the request is ready for the next
      question, because the client is not allowed to indicate that the user is ready for the next question
      until the answers to the current QuestionnaireResponse pass validation rules. The QuestionnaireResponse
      is compared against the Questionnaire contained within it, and the following are reported:

      - a question marked `required` that is enabled but has no answer
      - a question that has an answer even though it is not enabled
      - a group that has answers of its own, which belong to its nested questions instead
      - a question whose nested items appear directly under the item rather than within its answers

      Whether a question is enabled is determined by its `enableWhen` conditions, evaluated from the position
      in the QuestionnaireResponse where the question is, or would be, answered. The question that a condition
      references is resolved by searching the ancestors of that position first, then the items preceding it,
      then the items following it, and using the first item found with the referenced `linkId`. Questions
      nested within a question that is not enabled are not evaluated. When a question has multiple `enableWhen`
      conditions, at least one must be met unless `enableBehavior` is `all`, and when the referenced question
      has multiple answers, a condition is met if any of them satisfies it.

      Note that `required` only applies once the item holding the question is present, so a group that is
      itself optional may be left out of the QuestionnaireResponse along with the required questions within
      it. A group whose questions must be answered has to be marked `required` itself, and when such a group
      is missing it is reported in place of the questions within it.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-146'

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def check_questionnaire_response_readiness(questionnaire_response, request_index)
      # Without a contained Questionnaire there is nothing to check the answers against. An adaptive
      # QuestionnaireResponse has to contain one, but that is a profile constraint reported by the
      # validation above, so it is not repeated here.
      questionnaire = contained_questionnaire_from_questionnaire_response(questionnaire_response)
      return if questionnaire.blank?

      questionnaire_response_findings(questionnaire, questionnaire_response).each do |finding|
        add_request_message('error', finding.message, request_index)
      end
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])
      check_for_adaptive_short_circuit

      requests = load_tagged_requests(*target_tags)
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test'

      requests.each_with_index do |qp_request, request_index|
        unless qp_request.url == next_url
          add_request_message(
            'error',
            "Request made to wrong URL: #{qp_request.url}. Should instead be to #{next_url}.",
            request_index
          )
        end

        input_resource = parse_fhir_request_entity(qp_request.request_body, 'Request', request_index)
        unless input_resource.present?
          add_request_message(
            'error',
            'Request does not contain a recognized FHIR resource',
            request_index
          )
          next
        end

        if input_resource.is_a?(FHIR::QuestionnaireResponse)
          resource_is_valid?(resource: input_resource,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0',
                             message_prefix: request_prefix(request_index))

        elsif input_resource.is_a?(FHIR::Parameters)
          resource_is_valid?(resource: input_resource,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-next-question-input-parameters|2.2.0',
                             message_prefix: request_prefix(request_index))
        else
          add_request_message(
            'error',
            'Request body contains an unexpected resource type: ' \
            "expected Parameters or QuestionnaireResponse, got '#{input_resource.class}'",
            request_index
          )
        end

        questionnaire_response = questionnaire_response_from_next_question_request(input_resource)
        check_questionnaire_response_readiness(questionnaire_response, request_index) if questionnaire_response.present?
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $next-question request(s). See Messages for details."
      )
    end
  end
end
