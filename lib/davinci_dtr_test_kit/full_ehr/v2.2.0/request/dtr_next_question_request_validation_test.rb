require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../../cross_suite/v2.2.0/questionnaire_response_completeness'

module DaVinciDTRTestKit
  class DTRFullEHRV220NextQuestionRequestValidationTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper
    include QuestionnaireResponseCompleteness

    id :dtr_full_ehr_v220_nq_request_validation
    title 'Next Question request is valid'
    description %(
      This test validates the conformance of the client's request to the
      [DTR Next Question Input Parameters](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-next-question-input-parameters.html)
      structure. Because there is only a single in parameter, the request is allowed to be just a
      [DTR Questionnaire Response for adaptive form](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-dtr-questionnaireresponse-adapt.html)

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
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-146'

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def questionnaire_response_from_parameters(input_params)
      resource = input_params.parameter.find { |param| param.name == 'questionnaire-response' }&.resource
      resource if resource.is_a?(FHIR::QuestionnaireResponse)
    end

    def check_questionnaire_response_readiness(questionnaire_response, request_index)
      questionnaire = contained_questionnaire(questionnaire_response)
      if questionnaire.blank?
        add_request_message(
          'error',
          'Unable to verify that the QuestionnaireResponse is ready for the next question: it does not ' \
          'include a contained Questionnaire.',
          request_index
        )
        return
      end

      questionnaire_response_findings(questionnaire, questionnaire_response).each do |finding|
        add_request_message('error', finding.message, request_index)
      end
    end

    run do
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

        input_params = parse_fhir_request_entity(qp_request.request_body, 'Request', request_index)
        unless input_params.present?
          add_request_message(
            'error',
            'Request does not contain a recognized FHIR resource',
            request_index
          )
          next
        end

        if input_params.is_a?(FHIR::QuestionnaireResponse)
          resource_is_valid?(resource: input_params,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-questionnaireresponse-adapt|2.2.0',
                             message_prefix: request_prefix(request_index))
          check_questionnaire_response_readiness(input_params, request_index)

        elsif input_params.is_a?(FHIR::Parameters)
          resource_is_valid?(resource: input_params,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-next-question-input-parameters|2.2.0',
                             message_prefix: request_prefix(request_index))
          questionnaire_response = questionnaire_response_from_parameters(input_params)
          if questionnaire_response.present?
            check_questionnaire_response_readiness(questionnaire_response, request_index)
          end
        else
          add_request_message(
            'error',
            'Request is not FHIR Parameters resource',
            request_index
          )
        end
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $next-question request(s). See Messages for details."
      )
    end
  end
end
