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
    title 'Answers have the expected information-origin sources'
    description %(
      This test checks the [information-origin](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-information-origin.html)
      extension on each answer in the completed adaptive QuestionnaireResponse, which is the
      QuestionnaireResponse the client sent on the $next-question request that Inferno marked `completed`.

      Questionnaire items with an `initialExpression`, `calculatedExpression`, or `candidateExpression`
      are considered pre-populated. The test verifies that:
      - every answer has an information-origin extension with a `source`;
      - answers to pre-populated items have a source of `auto-client`, `auto-server`, or `override`;
      - answers to all other items have a source of `manual`;
      - at least one pre-populated answer was changed by the user (`override`), showing that users
        can revise pre-populated answers;
      - at least one pre-populated answer was left alone (`auto-client`), showing that users
        are not required to change pre-populated answers;
      - at least one answer that was not pre-populated was filled in by the user (`manual`).
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-132',
                          'hl7.fhir.us.davinci-dtr_2.2.0@spec-137'

    PREPOPULATED_ORIGIN_SOURCES = ['auto-client', 'auto-server', 'override'].freeze
    MANUAL_ORIGIN_SOURCES = ['manual'].freeze

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
                    'No answer was filled in manually: expected at least one answer to an item that is not ' \
                    'pre-populated with information-origin source `manual`.')
      end

      assert_no_error_messages('Answer origins do not show the expected sources. See Messages for details.')
    end
  end
end
