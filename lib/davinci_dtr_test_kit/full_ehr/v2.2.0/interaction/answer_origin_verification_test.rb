require_relative '../../../tags'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'
require_relative '../../../cross_suite/v2.2.0/answer_origin_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220AnswerOriginVerificationTest < Inferno::Test
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper
    include AnswerOriginHelper

    id :dtr_full_ehr_v220_answer_origin_verification
    title 'Answers have the expected information-origin details'
    description %(
      This test checks the [information-origin](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-information-origin.html)
      extension on each answer in the completed adaptive QuestionnaireResponse, which is the
      QuestionnaireResponse the client sent on the $next-question request that Inferno marked `completed`.

      Questionnaire items with an `initialExpression`, `calculatedExpression`, or `candidateExpression`
      are considered pre-populated. The test verifies that:
      - every answer has an information-origin extension with a `source`;
      - answers to pre-populated items have a source of `auto-client`, `auto-server`, `override`, or
        `manual` (when the item's expression found nothing and the user filled in the answer);
      - answers to all other items have a source of `manual`;
      - every answer the user filled in or changed (`manual` or `override`) has an `author` with a
        `practitioner` reference identifying the user;
      - at least one pre-populated answer was changed by the user (`override`), showing that users
        can revise pre-populated answers;
      - at least one pre-populated answer was left alone (`auto-client`), showing that users
        are not required to change pre-populated answers;
      - at least one answer was filled in by the user (`manual`).
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-132',
                          'hl7.fhir.us.davinci-dtr_2.2.0@spec-137'

    # A pre-populated item can still be answered 'manual' if its expression found nothing and the user
    # filled it in, since spec-137 only calls for 'override' when the answer was already populated.
    PREPOPULATED_ORIGIN_SOURCES = ['auto-client', 'auto-server', 'override', 'manual'].freeze
    MANUAL_ORIGIN_SOURCES = ['manual'].freeze
    USER_ENTERED_ORIGIN_SOURCES = ['override', 'manual'].freeze

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])
      check_for_adaptive_short_circuit

      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?
      requests = load_tagged_requests(*tags)
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test.'

      # Requests are in the order they were received, so search from the end to find the request whose
      # response Inferno marked `completed`. That request carries the final set of answers.
      completed_request = requests.reverse.find do |request|
        next false if request.response_body.blank?

        response_questionnaire_response =
          questionnaire_response_from_next_question_response(FHIR.from_contents(request.response_body))
        response_questionnaire_response&.status == 'completed'
      rescue JSON::ParserError
        false
      end
      skip_if completed_request.nil?,
              'No $next-question request resulted in a completed QuestionnaireResponse, ' \
              'so there are no final answers to check.'

      questionnaire_response = begin
        questionnaire_response_from_next_question_request(FHIR.from_contents(completed_request.request_body))
      rescue JSON::ParserError
        nil
      end
      skip_if questionnaire_response.nil?,
              'Could not find a QuestionnaireResponse in the completing $next-question request.'

      questionnaire = contained_questionnaire_from_questionnaire_response(questionnaire_response)
      skip_if questionnaire.nil?,
              'The completed QuestionnaireResponse does not contain the Questionnaire it answers.'

      questionnaire_items_by_link_id = {}
      all_questionnaire_items(questionnaire.item).each do |questionnaire_item|
        questionnaire_items_by_link_id[questionnaire_item.linkId] = questionnaire_item
      end

      # Walk every item in the QuestionnaireResponse. Items can be nested directly under other
      # items or beneath an answer, so both are added to the list as they are found.
      demonstrated_sources = []
      response_items_to_check = questionnaire_response.item.dup
      until response_items_to_check.empty?
        response_item = response_items_to_check.shift
        response_items_to_check.concat(response_item.item)
        link_id = response_item.linkId

        response_item.answer.each do |answer|
          response_items_to_check.concat(answer.item)

          origin_extension = answer.extension.find { |extension| extension.url == INFORMATION_ORIGIN_URL }
          source_extension = origin_extension&.extension&.find { |extension| extension.url == 'source' }
          source = source_extension&.value
          if source.nil?
            add_message('error',
                        "Answer to item `#{link_id}` is missing an information-origin extension with a `source`.")
            next
          end

          # spec-137: an answer the user filled in or changed must name the user as its author
          if USER_ENTERED_ORIGIN_SOURCES.include?(source)
            author_extension = origin_extension.extension.find { |extension| extension.url == 'author' }
            practitioner_extension = author_extension&.extension&.find { |extension| extension.url == 'practitioner' }
            if practitioner_extension&.value.nil?
              add_message('error',
                          "Answer to item `#{link_id}` has information-origin source `#{source}` but no `author` " \
                          'with a `practitioner` reference identifying the user who entered it.')
            end
          end

          if prepopulated_item?(questionnaire_items_by_link_id[link_id])
            item_description = 'pre-populated item'
            expected_sources = PREPOPULATED_ORIGIN_SOURCES
          else
            item_description = 'item that is not pre-populated'
            expected_sources = MANUAL_ORIGIN_SOURCES
          end

          if expected_sources.include?(source)
            demonstrated_sources << source
          else
            add_message('error',
                        "Answer to #{item_description} `#{link_id}` has information-origin source `#{source}`, " \
                        "expected one of: #{expected_sources.join(', ')}.")
          end
        end
      end

      unless demonstrated_sources.include?('override')
        add_message('error',
                    'No pre-populated answer was changed by the user: expected at least one answer to a ' \
                    'pre-populated item with information-origin source `override`.')
      end
      unless demonstrated_sources.include?('auto-client')
        add_message('error',
                    'No pre-populated answer was left unchanged: expected at least one answer to a ' \
                    'pre-populated item with information-origin source `auto-client`.')
      end
      unless demonstrated_sources.include?('manual')
        add_message('error',
                    'No answer was filled in manually: expected at least one answer with information-origin ' \
                    'source `manual`.')
      end

      assert_no_error_messages('Answer origins do not show the expected details. See Messages for details.')
    end
  end
end
