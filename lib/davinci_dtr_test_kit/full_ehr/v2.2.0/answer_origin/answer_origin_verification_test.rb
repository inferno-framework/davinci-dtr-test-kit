require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220AnswerOriginVerificationTest < Inferno::Test
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_answer_origin_verification
    title 'Answers have the expected information-origin details'
    description %(
      This test checks the [information-origin](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/StructureDefinition-information-origin.html)
      extension on the answers to the three questions in Inferno's answer origin Questionnaire, using the
      QuestionnaireResponse the client sent on the $next-question request that Inferno marked `completed`:
      - **Last Name (don't change!)** was pre-populated and left alone, so its source must be `auto-client`.
        This shows users are not required to change pre-populated answers.
      - **Preferred First Name (update)** was pre-populated and then changed, so its source must be `override`.
        This shows users can revise pre-populated answers.
      - **New Information (add details)** was not pre-populated and was typed in, so its source must be `manual`.

      The two answers the user entered (`override` and `manual`) must also have an `author` with a
      `practitioner` reference identifying the user.
    )
    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-132',
                          'hl7.fhir.us.davinci-dtr_2.2.0@spec-137'

    INFORMATION_ORIGIN_URL = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin'.freeze

    # The questions in Inferno's answer origin Questionnaire (fixtures/answer_origin) and what each answer
    # should show. Answers the user entered must name the user as their author (spec-137).
    EXPECTED_ANSWERS = [
      {
        link_id: 'last-name-do-not-change',
        text: "Last Name (don't change!)",
        source: 'auto-client',
        author_required: false,
        reason: 'it is pre-populated with the patient\'s last name and should be left unchanged. If it was ' \
                'not pre-populated, make sure the Patient has a recorded last name'
      },
      {
        link_id: 'preferred-first-name-update',
        text: 'Preferred First Name (update)',
        source: 'override',
        author_required: true,
        reason: 'it is pre-populated with the patient\'s first name and should be changed by the user. If it ' \
                'was not pre-populated, make sure the Patient has a recorded first name'
      },
      {
        link_id: 'new-information-add',
        text: 'New Information (add details)',
        source: 'manual',
        author_required: true,
        reason: 'it is not pre-populated and should be filled in by the user'
      }
    ].freeze

    run do
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?
      requests = load_tagged_requests(*tags)
      skip_if requests.blank?, 'A $next-question request must be made prior to running this test.'

      # Requests are in the order they were received, so search from the end to find the request whose
      # response Inferno marked `completed`. That request carries the final set of answers.
      # Bodies are checked for blank before parsing
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

      # The client sent the completing request, so a missing or unreadable QuestionnaireResponse in it is a
      # problem with the client.
      request_body = completed_request.request_body
      assert request_body.present?, 'The completing $next-question request has an empty body.'

      questionnaire_response = begin
        questionnaire_response_from_next_question_request(FHIR.from_contents(request_body))
      rescue JSON::ParserError
        nil
      end
      assert questionnaire_response.present?,
             'The completing $next-question request does not contain a valid QuestionnaireResponse.'

      # Collect the first answer to each item. Items can be nested directly under other items or
      # beneath an answer, so both are added to the list as they are found.
      answers_by_link_id = {}
      response_items_to_check = questionnaire_response.item.dup
      until response_items_to_check.empty?
        response_item = response_items_to_check.shift
        response_items_to_check.concat(response_item.item)
        response_item.answer.each { |answer| response_items_to_check.concat(answer.item) }
        answers_by_link_id[response_item.linkId] = response_item.answer.first if response_item.answer.present?
      end

      EXPECTED_ANSWERS.each do |expected|
        answer = answers_by_link_id[expected[:link_id]]
        if answer.nil?
          add_message('error', "No answer to `#{expected[:text]}` (linkId `#{expected[:link_id]}`).")
          next
        end

        origin_extension = answer.extension.find { |extension| extension.url == INFORMATION_ORIGIN_URL }
        source_extension = origin_extension&.extension&.find { |extension| extension.url == 'source' }
        source = source_extension&.value
        if source.nil?
          add_message('error',
                      "The answer to `#{expected[:text]}` is missing an information-origin extension with a " \
                      "`source`. Its source should be `#{expected[:source]}` because #{expected[:reason]}.")
        elsif source != expected[:source]
          add_message('error',
                      "The answer to `#{expected[:text]}` has information-origin source `#{source}`, but it should " \
                      "be `#{expected[:source]}` because #{expected[:reason]}.")
        end

        next unless expected[:author_required]

        author_extension = origin_extension&.extension&.find { |extension| extension.url == 'author' }
        practitioner_extension = author_extension&.extension&.find { |extension| extension.url == 'practitioner' }
        next unless practitioner_extension&.value.nil?

        add_message('error',
                    "The answer to `#{expected[:text]}` has no information-origin `author` with a `practitioner` " \
                    'reference identifying the user who entered it.')
      end

      assert_no_error_messages('Answer origins do not show the expected details. See Messages for details.')
    end
  end
end
