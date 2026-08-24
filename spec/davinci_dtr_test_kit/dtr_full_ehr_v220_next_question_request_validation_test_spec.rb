require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_next_question_request_validation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionRequestValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:runnable) { find_test(suite, 'dtr_full_ehr_v220_nq_request_validation') }
  let(:next_url) { "#{Inferno::Application['base_url']}/custom/#{suite_id}#{DaVinciDTRTestKit::NEXT_PATH}" }
  let(:request_tags) { [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'adaptive'] }

  # The initial $next-question request: the contained Questionnaire has no items yet, so there are
  # no required questions to answer.
  let(:initial_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_initial_input_params_conformant.json'))
  end

  # A follow-up $next-question request where every required question in the contained Questionnaire
  # has an answer.
  let(:all_answered_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_input_params_no_origin_extension.json'))
  end

  # A follow-up $next-question request where required question `3.1` has no answer.
  let(:missing_answer_request_body) do
    File.read(File.join(__dir__, '..', 'fixtures', 'next_question_input_params_missing_answer.json'))
  end

  before do
    # Profile validation is exercised elsewhere and requires the validator service.
    allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
  end

  def build_next_requests(*request_bodies)
    result = repo_create(:result, test_session_id: test_session.id)
    request_bodies.each do |request_body|
      repo_create(:request, result_id: result.id, url: next_url, request_body:,
                            test_session_id: test_session.id, tags: request_tags)
    end
  end

  def result_messages_string
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [runnable])
      .first.messages.map(&:message).join("\n")
  end

  def fixture(name)
    FHIR.from_contents(File.read(File.join(__dir__, '..', 'fixtures', name)))
  end

  # Builds a $next-question request body containing a QuestionnaireResponse for a Questionnaire with
  # the provided items. When `wrap_in_parameters` is false the QuestionnaireResponse is the body.
  def request_body_for(questionnaire_items:, response_items:, wrap_in_parameters: true)
    questionnaire_response = FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      questionnaire: '#DinnerOrderAdaptive',
      contained: [
        FHIR::Questionnaire.new(
          id: 'DinnerOrderAdaptive',
          url: 'urn:inferno:dtr-test-kit:dinner-order-adaptive',
          status: 'draft',
          item: questionnaire_items
        )
      ],
      item: response_items
    )
    return questionnaire_response.to_json unless wrap_in_parameters

    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: questionnaire_response)
      ]
    ).to_json
  end

  # Builds a request body from a Questionnaire and QuestionnaireResponse fixture pair by containing
  # the Questionnaire within the response, the way a client does for an adaptive form.
  def request_body_from_fixtures(questionnaire_name, response_name)
    questionnaire = fixture(questionnaire_name)
    questionnaire_response = fixture(response_name)
    questionnaire_response.contained = [questionnaire]
    questionnaire_response.questionnaire = "##{questionnaire.id}"
    FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'questionnaire-response', resource: questionnaire_response)
      ]
    ).to_json
  end

  it 'skips if no $next-question request was made' do
    result = run(runnable)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/next-question request must be made prior to running this test/)
  end

  it 'passes when the contained Questionnaire has no questions yet' do
    build_next_requests(initial_request_body)

    expect(run(runnable).result).to eq('pass')
  end

  it 'passes when all of the required questions have been answered' do
    build_next_requests(initial_request_body, all_answered_request_body)

    expect(run(runnable).result).to eq('pass')
  end

  it 'fails when a required question has not been answered' do
    build_next_requests(missing_answer_request_body)

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to match(/Item `3\.1` .* is required and enabled, but has no answer/)
  end

  it 'identifies the request containing the unanswered required question' do
    build_next_requests(initial_request_body, missing_answer_request_body)

    result = run(runnable)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Request 2:/)
    expect(result_messages_string).to match(/\(Request 2\) Item `3\.1`/)
  end

  it 'fails when a required question has not been answered in a bare QuestionnaireResponse body' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: true)],
        response_items: [],
        wrap_in_parameters: false
      )
    )

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to match(/Item `Q1` is required and enabled, but has no answer/)
  end

  it 'fails when the QuestionnaireResponse does not contain a Questionnaire' do
    build_next_requests(
      FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'questionnaire-response',
            resource: FHIR::QuestionnaireResponse.new(status: 'in-progress')
          )
        ]
      ).to_json
    )

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to match(/it does not include a contained Questionnaire/)
  end

  it 'passes when unanswered questions are not required' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: false)],
        response_items: []
      )
    )

    expect(run(runnable).result).to eq('pass')
  end

  describe 'when questions are gated by enableWhen conditions' do
    let(:trigger_question) { FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: false) }
    let(:gated_question) do
      FHIR::Questionnaire::Item.new(
        linkId: 'Q2', type: 'string', required: true,
        enableWhen: [
          FHIR::Questionnaire::Item::EnableWhen.new(question: 'Q1', operator: '=', answerString: 'no')
        ]
      )
    end

    def string_answer_item(link_id, value)
      FHIR::QuestionnaireResponse::Item.new(
        linkId: link_id,
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: value)]
      )
    end

    it 'passes when a required question is disabled by an unmet condition' do
      build_next_requests(
        request_body_for(questionnaire_items: [trigger_question, gated_question],
                         response_items: [string_answer_item('Q1', 'yes')])
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when a required question is enabled by a met condition and unanswered' do
      build_next_requests(
        request_body_for(questionnaire_items: [trigger_question, gated_question],
                         response_items: [string_answer_item('Q1', 'no')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/Item `Q2` is required and enabled, but has no answer/)
    end

    it 'fails when a question that is not enabled has been answered' do
      build_next_requests(
        request_body_for(questionnaire_items: [trigger_question, gated_question],
                         response_items: [string_answer_item('Q1', 'yes'), string_answer_item('Q2', 'an answer')])
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(
        /Item `Q2` has an answer, but is not enabled based on its `enableWhen` condition\(s\)/
      )
    end
  end

  # These fixtures come from the example Karl put together for the enableWhen design, where the same
  # linkIds appear under each answer of a repeating question.
  describe 'when the same question is answered under several answers of a repeating question' do
    it 'passes when each answer holds the questions that its own value enables' do
      build_next_requests(
        request_body_from_fixtures('enable_when_multiple_parent_questionnaire.json',
                                   'enable_when_multiple_parent_valid_response.json')
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'reports the missing and misplaced answers against the answer they belong to' do
      build_next_requests(
        request_body_from_fixtures('enable_when_multiple_parent_questionnaire.json',
                                   'enable_when_multiple_parent_invalid_response.json')
      )

      expect(run(runnable).result).to eq('fail')
      messages = result_messages_string
      expect(messages).to match(
        /Item `concern\.other` within `concern\[answer 1\]` has an answer, but is not enabled/
      )
      expect(messages).to match(
        /Item `concern\.contact` within `concern\[answer 1\]` has an answer, but is not enabled/
      )
      expect(messages).to match(
        /Item `concern\.other` within `concern\[answer 2\]` is required and enabled, but has no answer/
      )
      expect(messages).to match(
        /Item `concern\.contact` within `concern\[answer 2\]` is required and enabled, but has no answer/
      )
    end
  end
end
