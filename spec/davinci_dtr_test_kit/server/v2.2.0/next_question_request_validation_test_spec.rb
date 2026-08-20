RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::NextQuestionRequestValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def record_next_question_request(request_body)
    repo_create(
      :request,
      result:,
      request_body:,
      tags: [DaVinciDTRTestKit::NEXT_TAG],
      test_session_id: test_session.id
    )
  end

  it 'omits when no $next-question requests were made' do
    result = run(described_class)

    expect(result.result).to eq('omit')
    expect(result.result_message).to include('No $next-question requests were made')
  end

  it 'fails when a request body is not a recognized FHIR resource' do
    record_next_question_request('{}')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Non-conformant $next-question QuestionnaireResponse request')
    expect(result_messages.first.message).to include('[Resource 1] Resource does not contain a recognized FHIR object')
  end

  it 'fails when a request body is not QuestionnaireResponse' do
    record_next_question_request(FHIR::Parameters.new.to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Non-conformant $next-question QuestionnaireResponse request')
    expect(result_messages.first.message).to include(
      '[Resource 1] Unexpected resource type: expected QuestionnaireResponse'
    )
  end

  it 'fails when a request does not conform to the profile' do
    record_next_question_request(FHIR::QuestionnaireResponse.new.to_json)
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(false)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Non-conformant $next-question QuestionnaireResponse request')
    expect(result_messages.first.message).to include('[Resource 1] Resource does not conform to the profile')
  end

  it 'passes when every outgoing QuestionnaireResponse request conforms to the profile' do
    2.times { record_next_question_request(FHIR::QuestionnaireResponse.new.to_json) }
    expect_any_instance_of(described_class).to receive(:resource_is_valid?).twice.and_return(true)

    result = run(described_class)

    expect(result.result).to eq('pass')
  end
end
