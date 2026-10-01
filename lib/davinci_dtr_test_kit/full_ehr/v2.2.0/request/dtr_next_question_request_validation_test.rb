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
      is compared against the Questionnaire Inferno returned to the client: the one from the most recent
      earlier `$next-question` response for the same Questionnaire, or the one returned by
      `$questionnaire-package` when there is no such response or when it completed the Questionnaire. The
      following are reported:

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

      A question may also be enabled by an
      [enableWhenExpression](https://hl7.org/fhir/uv/sdc/STU4/en/StructureDefinition-sdc-questionnaire-enableWhenExpression.html)
      extension. Inferno does not evaluate these expressions, so such a question is presumed to have been
      handled correctly by the client, and an informational message records that the expression was not
      evaluated.

      Judging the answers against the Questionnaire Inferno returned, rather than against the copy contained
      in the request, means a client cannot excuse itself from a question by dropping it or turning it off:
      the questions Inferno asked still have to be answered, so the missing answers are reported. Working out
      that the contained Questionnaire was altered is then left to the tester.

      More than one adaptive Questionnaire may be completed during a single interaction, so earlier responses
      are matched to a request by the url and version of the Questionnaire it contains. For Inferno to pair
      each request with the Questionnaire it was given, complete an adaptive Questionnaire before starting
      another one, and if one cannot be completed, abort the test rather than starting that Questionnaire
      over. A request that follows a response whose QuestionnaireResponse had a `status` of `completed` is
      taken to be starting that Questionnaire again, and is compared against the Questionnaire that
      `$questionnaire-package` returned.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-146'

    def target_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def package_target_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    # Read rather than validated here, so they are fetched directly instead of being added to this
    # test's own list of requests. Tagged requests arrive without their bodies, so each one is loaded
    # in full.
    def questionnaire_package_responses
      @questionnaire_package_responses ||= begin
        requests_repo = Inferno::Repositories::Requests.new
        requests_repo.tagged_requests(test_session_id, package_target_tags)
          .map { |package_request| requests_repo.find_full_request(package_request.id) }
          .filter_map { |package_request| parsed_package_response(package_request) }
      end
    end

    def parsed_package_response(package_request)
      return nil if package_request&.response_body.blank?

      parsed = FHIR.from_contents(package_request.response_body)
      parsed if parsed.is_a?(FHIR::Parameters)
    rescue JSON::ParserError
      nil # a malformed response is reported by the package response validation test
    end

    # The Questionnaires the package offered the client to start from. A QuestionnaireResponse in the
    # package carries the Questionnaire an adaptive form begins with, so those come first.
    def packaged_questionnaires
      @packaged_questionnaires ||= questionnaire_package_responses.flat_map do |parameters|
        resources = questionnaire_package_bundles(parameters).flat_map { |bundle| Array(bundle.entry).map(&:resource) }
        resources.grep(FHIR::QuestionnaireResponse)
          .filter_map { |response| contained_questionnaire_from_questionnaire_response(response) } +
          resources.grep(FHIR::Questionnaire)
      end
    end

    # Two Questionnaires are the same one when their urls match and, where the one being looked for
    # names a version, their versions match too. A reference without a version matches any version,
    # since that is what a canonical without a version means.
    def questionnaire_matches?(candidate, reference)
      return false if candidate.blank? || reference.blank?

      candidate.url == reference.url && (reference.version.blank? || candidate.version == reference.version)
    end

    # `derivedFrom` holds canonicals as strings rather than Questionnaires, so they are compared by
    # the same rule after splitting the version off.
    def canonical_matches?(candidate, canonical)
      return false if candidate.blank? || canonical.blank?

      url, version = canonical.split('|', 2)
      candidate.url == url && (version.blank? || candidate.version == version)
    end

    # The first request has no previous response, so what the client started from is whichever
    # Questionnaire the package returned for the canonical its contained Questionnaire names.
    def packaged_questionnaire_for(questionnaire)
      return nil if questionnaire.blank?

      packaged_questionnaires.find do |packaged|
        questionnaire_matches?(packaged, questionnaire) ||
          Array(questionnaire.derivedFrom).any? { |canonical| canonical_matches?(packaged, canonical) }
      end
    end

    # The QuestionnaireResponse the payer returned earlier for the Questionnaire this request names.
    # More than one adaptive Questionnaire may be worked on during a single interaction, so the search
    # runs backwards from the request being checked and takes the most recent response whose contained
    # Questionnaire carries the same url and version, rather than assuming the request immediately
    # before this one was for the same Questionnaire.
    def previously_returned_questionnaire_response(requests, request_index, request_questionnaire)
      return nil if request_index.zero? || request_questionnaire.blank?

      (request_index - 1).downto(0) do |previous_index|
        returned_response = returned_questionnaire_response(requests[previous_index])
        returned_questionnaire = contained_questionnaire_from_questionnaire_response(returned_response)

        return returned_response if questionnaire_matches?(returned_questionnaire, request_questionnaire)
      end

      nil
    end

    def returned_questionnaire_response(request)
      return nil if request.response_body.blank?

      questionnaire_response_from_next_question_response(FHIR.from_contents(request.response_body))
    rescue JSON::ParserError
      nil # a malformed response is reported by the response validation test
    end

    # What Inferno gave the client to answer: the Questionnaire from the previous `$next-question`
    # response for this Questionnaire, or whichever Questionnaire `$questionnaire-package` returned for
    # the canonical the client named. The package Questionnaire is the right one both for the first
    # request of a Questionnaire and when the previous response completed it, because a request that
    # follows a completed QuestionnaireResponse starts the Questionnaire over.
    def questionnaire_inferno_returned(requests, request_index, questionnaire_response)
      request_questionnaire = contained_questionnaire_from_questionnaire_response(questionnaire_response)
      previous_response = previously_returned_questionnaire_response(requests, request_index, request_questionnaire)
      if previous_response.blank? || previous_response.status == 'completed'
        return packaged_questionnaire_for(request_questionnaire)
      end

      contained_questionnaire_from_questionnaire_response(previous_response)
    end

    # The answers are judged against the Questionnaire Inferno returned rather than the copy the client
    # embedded, so a client that drops or alters a question does not excuse itself from answering it:
    # the answers it owes simply turn up missing. The embedded copy is used only when Inferno has
    # nothing on record to compare with, which leaves a check in place rather than none at all.
    def check_questionnaire_response_readiness(questionnaire_response, returned_questionnaire, request_index)
      questionnaire = returned_questionnaire ||
                      contained_questionnaire_from_questionnaire_response(questionnaire_response)
      return if questionnaire.blank?

      questionnaire_response_findings(questionnaire, questionnaire_response).each do |finding|
        add_request_message(finding.severity.to_s, finding.message, request_index)
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
        next if questionnaire_response.blank?

        returned_questionnaire = questionnaire_inferno_returned(requests, request_index, questionnaire_response)
        check_questionnaire_response_readiness(questionnaire_response, returned_questionnaire, request_index)
      end

      assert_no_error_messages(
        "#{requests_with_errors_prefix}Non-conformant $next-question request(s). See Messages for details."
      )
    end
  end
end
