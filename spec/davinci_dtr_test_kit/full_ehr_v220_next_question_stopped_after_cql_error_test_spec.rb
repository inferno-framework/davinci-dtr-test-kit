require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_next_question_stopped_after_cql_error_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220NextQuestionStoppedAfterCQLErrorTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:nq_url) { '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question' }

  def create_nq_request(response_body, status: 200, tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG])
    repo_create(
      :request,
      direction: 'incoming',
      url: nq_url,
      test_session_id: test_session.id,
      result:,
      request_body: '{}',
      response_body:,
      tags:,
      status:
    )
  end

  # A $next-question response: a QuestionnaireResponse whose contained Questionnaire holds the
  # items returned so far, nested the way the dinner questionnaire nests them.
  def nq_response_json(*link_ids)
    {
      resourceType: 'QuestionnaireResponse',
      status: 'in-progress',
      questionnaire: '#q',
      contained: [
        { resourceType: 'Questionnaire', id: 'q', status: 'draft',
          url: 'urn:inferno:dtr-test-kit:dinner-order-cql-error',
          item: [{ linkId: '3', type: 'group', item: link_ids.map { |link_id| { linkId: link_id, type: 'string' } } }] }
      ]
    }.to_json
  end

  it 'skips when no $next-question requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('A $next-question request must be made')
  end

  it 'skips when no response returned the item containing the malformed CQL' do
    create_nq_request(nq_response_json('3.1'))
    create_nq_request(nq_response_json('3.1', '3.2.a'))

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include("linkId '3.3'")
    expect(result.result_message).to include('never exposed to the error')
  end

  it 'passes when the response containing the error item is the last $next-question exchange' do
    create_nq_request(nq_response_json('3.1'))
    create_nq_request(nq_response_json('3.1', '3.2.a', '3.3'))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(result.result_message).to include('$next-question response 2')
  end

  it 'fails, counting the extra requests, when the client keeps calling $next-question after the error' do
    create_nq_request(nq_response_json('3.1'))
    create_nq_request(nq_response_json('3.1', '3.3'))
    create_nq_request(nq_response_json('3.1', '3.3'))
    create_nq_request(nq_response_json('3.1', '3.3'))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('made 2 $next-question request(s) after')
    expect(result.result_message).to include('$next-question response 2')
  end

  it 'ignores unsuccessful responses and responses that are not a QuestionnaireResponse' do
    create_nq_request({ resourceType: 'OperationOutcome', issue: [] }.to_json, status: 400)
    create_nq_request('not json')
    create_nq_request(nq_response_json('3.1', '3.3'))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
    expect(result.result_message).to include('$next-question response 3')
  end

  it 'uses the configured cql_error_item_link_id' do
    configured_class = Class.new(described_class) do
      id :configured_link_id_nq_stopped_spec_test
      config options: { cql_error_item_link_id: '3.2.a' }
    end
    Inferno::Repositories::Tests.new.insert(configured_class)
    create_nq_request(nq_response_json('3.1', '3.2.a'))
    create_nq_request(nq_response_json('3.1', '3.2.a', '3.3'))

    result = run(configured_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include("linkId '3.2.a'")
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_nq_stopped_after_cql_error_spec_test
        config options: { dtr_workflow_tag: 'cql_error' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    end

    it 'ignores requests tagged for a different workflow' do
      create_nq_request(nq_response_json('3.1', '3.3'), tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'adaptive'])

      result = run(scoped_test_class)

      expect(result.result).to eq('skip')
    end

    it 'only considers requests tagged for the configured workflow' do
      create_nq_request(nq_response_json('3.1', '3.3'), tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'cql_error'])
      create_nq_request(nq_response_json('3.1', '3.3'), tags: [DaVinciDTRTestKit::CLIENT_NEXT_TAG, 'adaptive'])

      result = run(scoped_test_class)

      expect(result.result).to eq('pass'), result.result_message
    end
  end
end
