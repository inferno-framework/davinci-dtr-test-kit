require 'davinci_dtr_test_kit/full_ehr/v2.2.0/resume/resume_answer_sequence_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220ResumeAnswerSequenceTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:before_pause) { described_class::BEFORE_PAUSE_TAG }
  let(:after_pause) { described_class::AFTER_PAUSE_TAG }

  # Results returned directly by `run` don't carry their messages, so reload them from the session.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  def questionnaire_response(answers, status: 'in-progress')
    {
      resourceType: 'QuestionnaireResponse',
      status:,
      item: answers.map do |link_id, value|
        { linkId: link_id, answer: value.nil? ? [] : [{ valueString: value }] }
      end
    }
  end

  # A $next-question request whose QuestionnaireResponse has the given answers (nil for an
  # unanswered question). `completed` sets the status Inferno returned.
  def create_nq_request(interaction_tag, answers, completed: false)
    request_body = { resourceType: 'Parameters',
                     parameter: [{ name: 'questionnaire-response', resource: questionnaire_response(answers) }] }
    response_body = questionnaire_response(answers, status: completed ? 'completed' : 'in-progress')
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
      test_session_id: test_session.id,
      result:,
      request_body: request_body.to_json,
      response_body: response_body.to_json,
      status: 200,
      tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG, interaction_tag]
    )
  end

  def create_full_sequence
    create_nq_request(before_pause, {})
    create_nq_request(before_pause, { 'question-1' => 'first' })
    create_nq_request(after_pause, { 'question-1' => 'first', 'question-2' => 'second' })
    create_nq_request(after_pause, { 'question-1' => 'first', 'question-2' => 'second', 'question-3' => 'third' },
                      completed: true)
  end

  it 'passes when question 1 is answered before saving, kept after resuming, and the response is completed' do
    create_full_sequence

    expect(run(described_class).result).to eq('pass')
  end

  it 'skips when no $next-question requests were made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No $next-question requests were made during this scenario.')
  end

  it 'fails when question 1 was not answered before saving' do
    create_nq_request(before_pause, {})
    create_nq_request(after_pause, { 'question-1' => 'first', 'question-2' => 'second', 'question-3' => 'third' },
                      completed: true)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('no $next-question request included an answer to question 1')
  end

  it 'fails when question 2 was answered before saving' do
    create_nq_request(before_pause, { 'question-1' => 'first' })
    create_nq_request(before_pause, { 'question-1' => 'first', 'question-2' => 'second' })
    create_nq_request(after_pause, { 'question-1' => 'first', 'question-2' => 'second', 'question-3' => 'third' },
                      completed: true)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Question 2 was answered before the QuestionnaireResponse was saved.')
  end

  it 'fails when no $next-question requests were made after resuming' do
    create_nq_request(before_pause, { 'question-1' => 'first' })

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message)
      .to eq('No $next-question requests were made after resuming the QuestionnaireResponse.')
  end

  it 'fails when a request after resuming lost the answer to question 1' do
    create_nq_request(before_pause, { 'question-1' => 'first' })
    create_nq_request(after_pause, { 'question-1' => nil, 'question-2' => 'second', 'question-3' => 'third' },
                      completed: true)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message)
      .to include('After resuming, $next-question request 1 did not include the answer to question 1.')
  end

  it 'fails when the answer to question 1 changed after resuming' do
    create_nq_request(before_pause, { 'question-1' => 'first' })
    create_nq_request(after_pause, { 'question-1' => 'other', 'question-2' => 'second', 'question-3' => 'third' },
                      completed: true)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message)
      .to include('answered question 1 with `other`, not the `first` saved before.')
  end

  it 'fails when the resumed QuestionnaireResponse was never completed' do
    create_nq_request(before_pause, { 'question-1' => 'first' })
    create_nq_request(after_pause, { 'question-1' => 'first', 'question-2' => 'second' })

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Inferno never marked the QuestionnaireResponse `completed`')
  end

  it 'adds a message for each problem and counts them in the result message' do
    create_nq_request(before_pause, { 'question-1' => 'first', 'question-2' => 'second' })
    create_nq_request(after_pause, { 'question-1' => 'other', 'question-2' => 'second' })

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'The $next-question requests show 3 problems with saving and resuming the QuestionnaireResponse. ' \
      'See Messages for details.'
    )
    expect(messages_for(result)).to contain_exactly(
      a_string_including('Question 2 was answered before the QuestionnaireResponse was saved.'),
      a_string_including('answered question 1 with `other`, not the `first` saved before.'),
      a_string_including('Inferno never marked the QuestionnaireResponse `completed`')
    )
  end

  it 'ignores requests from other workflows and waits' do
    create_full_sequence
    create_nq_request('some_other_wait', { 'question-1' => 'different', 'question-2' => 'early' })

    expect(run(described_class).result).to eq('pass')
  end
end
