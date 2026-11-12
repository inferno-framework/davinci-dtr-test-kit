require_relative '../../../tags'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220ResumeAnswerSequenceTest < Inferno::Test
    include QuestionnaireHelper

    # Tags the resume group's two waits add to their requests (dtr_interaction_tag).
    BEFORE_PAUSE_TAG = 'resume_before_pause'.freeze
    AFTER_PAUSE_TAG = 'resume_after_pause'.freeze
    # Question linkIds in fixtures/resume/resume_adaptive_next_question_template.json.
    QUESTION_1 = 'question-1'.freeze
    QUESTION_2 = 'question-2'.freeze
    QUESTION_3 = 'question-3'.freeze

    id :dtr_full_ehr_v220_resume_answer_sequence
    title 'Client saves the QuestionnaireResponse part-way through and resumes it with its answers'
    description %(
      The DTR IG [requires](https://hl7.org/fhir/us/davinci-dtr/2.2.0/en/specification.html#ci-c-spec-151)
      that a DTR client be able to save an in-progress QuestionnaireResponse before it is complete,
      and relaunch it later.

      During this test, Inferno verifies from the $next-question requests made during the two
      previous tests that
      - before the QuestionnaireResponse was saved, question 1 was answered and question 2 was not,
      - after resuming, each request still included the answer given to question 1 before saving, and
      - after resuming, questions 2 and 3 were answered and Inferno marked the QuestionnaireResponse
        `completed`.
    )

    verifies_requirements 'hl7.fhir.us.davinci-dtr_2.2.0@spec-151'

    def nq_requests(interaction_tag)
      tags = [CLIENT_NEXT_TAG, interaction_tag]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?
      load_tagged_requests(*tags)
    end

    run do
      before_pause = nq_requests(BEFORE_PAUSE_TAG)
      after_pause = nq_requests(AFTER_PAUSE_TAG)
      skip_if before_pause.blank? && after_pause.blank?,
              'No $next-question requests were made during this scenario.'

      errors = before_pause_errors(before_pause) + after_pause_errors(after_pause, saved_answer(before_pause))
      errors.each { |error| add_message('error', error) }
      assert_no_error_messages(failure_summary(errors))
    end

    private

    # One problem is named in full; several are counted, with the details in Messages.
    def failure_summary(errors)
      return errors.first if errors.one?

      "The $next-question requests show #{errors.length} problems with saving and resuming the " \
        'QuestionnaireResponse. See Messages for details.'
    end

    def before_pause_errors(requests)
      errors = []
      unless requests.any? { |request| answer(request, QUESTION_1).present? }
        errors << 'Before the QuestionnaireResponse was saved, no $next-question request included an answer ' \
                  'to question 1, so Inferno never returned question 2.'
      end
      if requests.any? { |request| answer(request, QUESTION_2).present? }
        errors << 'Question 2 was answered before the QuestionnaireResponse was saved. Save it and close DTR ' \
                  'after question 2 is returned, and answer question 2 after resuming.'
      end
      errors
    end

    def after_pause_errors(requests, saved_answer)
      return ['No $next-question requests were made after resuming the QuestionnaireResponse.'] if requests.blank?

      errors = requests.each_with_index.filter_map do |request, index|
        resumed_answer_error(answer(request, QUESTION_1), saved_answer, index)
      end
      unless requests.any? { |request| answer(request, QUESTION_2).present? }
        errors << 'After resuming, no $next-question request included an answer to question 2.'
      end
      unless requests.any? { |request| completed?(request) }
        errors << 'After resuming, Inferno never marked the QuestionnaireResponse `completed`: no ' \
                  '$next-question request answered all three questions.'
      end
      errors
    end

    def resumed_answer_error(resumed_answer, saved_answer, index)
      if resumed_answer.blank?
        "After resuming, $next-question request #{index + 1} did not include the answer to question 1."
      elsif saved_answer.present? && resumed_answer != saved_answer
        "After resuming, $next-question request #{index + 1} answered question 1 with " \
          "`#{resumed_answer}`, not the `#{saved_answer}` saved before."
      end
    end

    # The question 1 answer in the last request before the QuestionnaireResponse was saved.
    def saved_answer(requests)
      requests.filter_map { |request| answer(request, QUESTION_1) }.last
    end

    def answer(request, link_id)
      questionnaire_response = request_questionnaire_response(request)
      return if questionnaire_response.nil?

      item = find_item(questionnaire_response.item, link_id)
      return if item.nil?

      item.answer.filter_map(&:value).first&.to_s.presence
    end

    def find_item(items, link_id)
      items.each do |item|
        return item if item.linkId == link_id

        nested = find_item(item.item || [], link_id)
        return nested if nested.present?
      end
      nil
    end

    def request_questionnaire_response(request)
      return if request.request_body.blank?

      questionnaire_response_from_next_question_request(FHIR.from_contents(request.request_body))
    rescue JSON::ParserError
      nil
    end

    def completed?(request)
      return false if request.response_body.blank?

      questionnaire_response_from_next_question_response(FHIR.from_contents(request.response_body))
        &.status == 'completed'
    rescue JSON::ParserError
      false
    end
  end
end
