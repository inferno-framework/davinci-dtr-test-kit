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
    expect(result_messages_string).to match(
      /All required questions must be answered before requesting the next question.*`3\.1`/
    )
  end

  it 'identifies the request containing the unanswered required question' do
    build_next_requests(initial_request_body, missing_answer_request_body)

    result = run(runnable)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Request 2:/)
    expect(result_messages_string).to match(/\(Request 2\) All required questions must be answered/)
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
    expect(result_messages_string).to match(/No answer found for required item\(s\): `Q1`/)
  end

  it 'fails when a required question nested within an answered question has not been answered' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [
          FHIR::Questionnaire::Item.new(
            linkId: 'Q1', type: 'string', required: true,
            item: [FHIR::Questionnaire::Item.new(linkId: 'Q1.1', type: 'string', required: true)]
          )
        ],
        response_items: [
          FHIR::QuestionnaireResponse::Item.new(
            linkId: 'Q1',
            answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'an answer')]
          )
        ]
      )
    )

    expect(run(runnable).result).to eq('fail')
    expect(result_messages_string).to match(/No answer found for required item\(s\): `Q1\.1`/)
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
    expect(result_messages_string).to match(/does not include a contained Questionnaire/)
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

  it 'treats a boolean false answer to a required question as answered' do
    build_next_requests(
      request_body_for(
        questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'boolean', required: true)],
        response_items: [
          FHIR::QuestionnaireResponse::Item.new(
            linkId: 'Q1',
            answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueBoolean: false)]
          )
        ]
      )
    )

    expect(run(runnable).result).to eq('pass')
  end

  describe 'when required questions are gated by enableWhen conditions' do
    def enable_when(question, operator, answer_attributes)
      FHIR::Questionnaire::Item::EnableWhen.new({ question:, operator: }.merge(answer_attributes))
    end

    def string_answer_item(link_id, *values)
      FHIR::QuestionnaireResponse::Item.new(
        linkId: link_id,
        answer: values.map { |value| FHIR::QuestionnaireResponse::Item::Answer.new(valueString: value) }
      )
    end

    def gated_question(enable_when_conditions, enable_behavior: nil)
      FHIR::Questionnaire::Item.new(linkId: 'Q2', type: 'string', required: true,
                                    enableWhen: enable_when_conditions, enableBehavior: enable_behavior)
    end

    let(:trigger_question) { FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'string', required: false) }

    it 'passes when a required question is disabled by an unmet enableWhen condition' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question,
                                gated_question([enable_when('Q1', '=', { answerString: 'no' })])],
          response_items: [string_answer_item('Q1', 'yes')]
        )
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when a required question is enabled by a met enableWhen condition and unanswered' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question,
                                gated_question([enable_when('Q1', '=', { answerString: 'no' })])],
          response_items: [string_answer_item('Q1', 'no')]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/No answer found for required item\(s\): `Q2`/)
    end

    it 'fails when any one of multiple answers to the referenced question meets the condition' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question,
                                gated_question([enable_when('Q1', '=', { answerString: 'no' })])],
          response_items: [string_answer_item('Q1', 'maybe', 'no')]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/No answer found for required item\(s\): `Q2`/)
    end

    it 'passes when enableBehavior is all and only one of the conditions is met' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [
            trigger_question,
            FHIR::Questionnaire::Item.new(linkId: 'Q1b', type: 'string', required: false),
            gated_question([enable_when('Q1', '=', { answerString: 'no' }),
                            enable_when('Q1b', '=', { answerString: 'yes' })], enable_behavior: 'all')
          ],
          response_items: [string_answer_item('Q1', 'no'), string_answer_item('Q1b', 'other')]
        )
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when enableBehavior is absent and one of the conditions is met' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [
            trigger_question,
            FHIR::Questionnaire::Item.new(linkId: 'Q1b', type: 'string', required: false),
            gated_question([enable_when('Q1', '=', { answerString: 'no' }),
                            enable_when('Q1b', '=', { answerString: 'yes' })])
          ],
          response_items: [string_answer_item('Q1', 'no'), string_answer_item('Q1b', 'other')]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/No answer found for required item\(s\): `Q2`/)
    end

    it 'passes when an exists condition expecting an answer is unmet' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question,
                                gated_question([enable_when('Q1', 'exists', { answerBoolean: true })])],
          response_items: []
        )
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'fails when an exists condition expecting no answer is met' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question,
                                gated_question([enable_when('Q1', 'exists', { answerBoolean: false })])],
          response_items: []
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/No answer found for required item\(s\): `Q2`/)
    end

    it 'evaluates ordering comparison conditions against numeric answers' do
      integer_answer = FHIR::QuestionnaireResponse::Item.new(
        linkId: 'Q1',
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueInteger: 5)]
      )
      build_next_requests(
        request_body_for(
          questionnaire_items: [FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'integer', required: false),
                                gated_question([enable_when('Q1', '>', { answerInteger: 3 })])],
          response_items: [integer_answer]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/No answer found for required item\(s\): `Q2`/)
    end

    it 'compares Coding answers by system and code' do
      coding_answer = FHIR::QuestionnaireResponse::Item.new(
        linkId: 'Q1',
        answer: [FHIR::QuestionnaireResponse::Item::Answer.new(
          valueCoding: FHIR::Coding.new(system: 'http://example.com/cs', code: 'burger', display: 'Hamburger')
        )]
      )
      build_next_requests(
        request_body_for(
          questionnaire_items: [
            FHIR::Questionnaire::Item.new(linkId: 'Q1', type: 'choice', required: false),
            gated_question([enable_when('Q1', '=',
                                        { answerCoding: FHIR::Coding.new(system: 'http://example.com/cs',
                                                                         code: 'burger') })])
          ],
          response_items: [coding_answer]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(/No answer found for required item\(s\): `Q2`/)
    end

    it 'passes when a required question is nested within a disabled question' do
      disabled_group = FHIR::Questionnaire::Item.new(
        linkId: 'Group1', type: 'group',
        enableWhen: [enable_when('Q1', '=', { answerString: 'no' })],
        item: [FHIR::Questionnaire::Item.new(linkId: 'Q2', type: 'string', required: true)]
      )
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question, disabled_group],
          response_items: [string_answer_item('Q1', 'yes')]
        )
      )

      expect(run(runnable).result).to eq('pass')
    end

    it 'reports an error when a condition references a question with multiple occurrences' do
      build_next_requests(
        request_body_for(
          questionnaire_items: [trigger_question,
                                gated_question([enable_when('Q1', '=', { answerString: 'no' })])],
          response_items: [string_answer_item('Q1', 'yes'), string_answer_item('Q1', 'no')]
        )
      )

      expect(run(runnable).result).to eq('fail')
      expect(result_messages_string).to match(
        /Unable to verify that all required questions have been answered: multiple questions with linkId `Q1`/
      )
    end
  end
end
