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

      This test also verifies that all of the required questions in the QuestionnaireResponse provided in the
      request have been answered, because the client is not allowed to indicate that the user is ready for
      the next question until the answers to the current QuestionnaireResponse pass validation rules. The
      required questions are the items marked `required` in the Questionnaire contained within the
      QuestionnaireResponse, excluding questions that are disabled based on their `enableWhen` conditions
      and questions nested within disabled questions. When a question has multiple `enableWhen` conditions,
      at least one must be met unless `enableBehavior` is `all`, and when the question referenced by a
      condition has multiple answers, the condition is met if any answer satisfies it. Evaluation of a
      condition that references a question appearing more than once in the QuestionnaireResponse is not
      supported and is reported as an error.
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

    def check_required_questions_answered(questionnaire_response, request_index)
      questionnaire = contained_questionnaire(questionnaire_response)
      if questionnaire.blank?
        add_request_message(
          'error',
          'Unable to verify that all required questions have been answered: the QuestionnaireResponse ' \
          'does not include a contained Questionnaire.',
          request_index
        )
        return
      end

      unanswered_link_ids = unanswered_required_link_ids(questionnaire, questionnaire_response)
      return if unanswered_link_ids.empty?

      add_request_message(
        'error',
        'All required questions must be answered before requesting the next question. No answer found ' \
        "for required item(s): #{unanswered_link_ids.map { |link_id| "`#{link_id}`" }.to_sentence}.",
        request_index
      )
    rescue QuestionnaireResponseCompleteness::DuplicateLinkIdError => e
      add_request_message(
        'error',
        "Unable to verify that all required questions have been answered: #{e.message}",
        request_index
      )
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
          check_required_questions_answered(input_params, request_index)

        elsif input_params.is_a?(FHIR::Parameters)
          resource_is_valid?(resource: input_params,
                             profile_url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-next-question-input-parameters|2.2.0',
                             message_prefix: request_prefix(request_index))
          questionnaire_response = questionnaire_response_from_parameters(input_params)
          check_required_questions_answered(questionnaire_response, request_index) if questionnaire_response.present?
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
