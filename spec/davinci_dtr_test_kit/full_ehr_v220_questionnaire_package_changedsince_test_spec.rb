require 'davinci_dtr_test_kit/full_ehr/v2.2.0/request/dtr_questionnaire_package_changedsince_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnairePackageChangedSinceTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:qp_url) { described_class.new.questionnaire_package_url }
  let(:retrieved_at) { utc_time(2026, 11, 4, 20, 0, 0) }
  let(:resumed_at) { utc_time(2026, 11, 4, 20, 30, 0) }

  # The test database stores request timestamps without a zone and reads them back as local
  # time, as Inferno does with the Time.now it records. Build times in the local zone so they
  # read back as the same instant wherever the specs run.
  def utc_time(*)
    Time.utc(*).getlocal
  end

  # Results returned directly by `run` don't carry their messages, so reload them from the session.
  def messages_for(run_result)
    Inferno::Repositories::Results.new
      .current_results_for_test_session(test_session.id)
      .find { |candidate| candidate.id == run_result.id }
      &.messages&.map(&:message) || []
  end

  def request_body(changedsince: nil, value_type: 'valueInstant')
    parameters = [{ name: 'coverage', resource: { resourceType: 'Coverage', status: 'active' } },
                  { name: 'questionnaire', valueCanonical: 'urn:inferno:dtr-test-kit:dinner-order-static' }]
    parameters << { name: 'changedsince', value_type => changedsince } if changedsince
    { resourceType: 'Parameters', parameter: parameters }.to_json
  end

  def package_response
    { resourceType: 'Parameters',
      parameter: [{ name: 'packagebundle', resource: { resourceType: 'Bundle', type: 'collection' } }] }.to_json
  end

  def unchanged_response
    { resourceType: 'Parameters',
      parameter: [{ name: 'outcome',
                    resource: { resourceType: 'OperationOutcome',
                                issue: [{ severity: 'information', code: 'informational' }] } }] }.to_json
  end

  def create_qp_request(created_at:, request_body:, response_body:, status: 200)
    repo_create(
      :request,
      direction: 'incoming',
      url: qp_url,
      test_session_id: test_session.id,
      result:,
      request_body:,
      response_body:,
      status:,
      created_at:,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG]
    )
  end

  def create_retrieval(created_at: retrieved_at)
    create_qp_request(created_at:, request_body: request_body, response_body: package_response)
  end

  def create_resumed_request(changedsince, created_at: resumed_at, value_type: 'valueInstant')
    create_qp_request(created_at:, request_body: request_body(changedsince:, value_type:),
                      response_body: unchanged_response)
  end

  it 'skips when no Questionnaire Package requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('A Questionnaire Package request must be made')
  end

  it 'skips when Inferno never returned a Questionnaire package' do
    create_qp_request(created_at: retrieved_at, request_body: request_body,
                      response_body: FHIR::OperationOutcome.new.to_json, status: 400)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('did not return a Questionnaire package')
  end

  it 'fails when no request includes changedsince' do
    create_retrieval
    create_retrieval(created_at: resumed_at)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('No $questionnaire-package request included the `changedsince` parameter')
  end

  it 'passes when changedsince falls between the first retrieval and the resumed request' do
    create_retrieval
    create_resumed_request('2026-11-04T20:10:00Z')

    result = run(described_class)

    expect(result.result).to eq('pass')
  end

  it 'passes when changedsince equals the first retrieval time and uses a time zone offset' do
    create_retrieval
    create_resumed_request('2026-11-04T15:00:00-05:00')

    expect(run(described_class).result).to eq('pass')
  end

  it 'allows for up to a minute of clock difference on either side of the window' do
    create_retrieval
    create_resumed_request('2026-11-04T19:59:01Z')
    create_resumed_request('2026-11-04T20:30:59Z')

    expect(run(described_class).result).to eq('pass')
  end

  it 'fails when changedsince is not sent as valueInstant' do
    create_retrieval
    create_resumed_request('2026-11-04T20:10:00Z', value_type: 'valueDateTime')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Request 2:')
    expect(messages_for(result)).to include(a_string_matching(/must be provided as `valueInstant`/))
  end

  it 'fails when changedsince is not a full instant' do
    create_retrieval
    create_resumed_request('2026-11-04')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(a_string_matching(/`2026-11-04` is not a valid instant/))
  end

  it 'fails when changedsince is more than a minute earlier than the first retrieval' do
    create_retrieval
    create_resumed_request('2026-11-04T19:58:59Z')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result)).to include(
      a_string_matching(/is earlier than the time Inferno first returned a Questionnaire package, 2026-11-04T20:00:00Z/)
    )
  end

  it 'fails when changedsince is more than a minute later than the request' do
    create_retrieval
    create_resumed_request('2026-11-04T20:31:01Z')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(messages_for(result))
      .to include(a_string_matching(/is later than the time of the request, 2026-11-04T20:30:00Z/))
  end

  it 'fails when the request with changedsince was made before a package was returned' do
    create_resumed_request('2026-11-04T19:00:00Z', created_at: utc_time(2026, 11, 4, 19, 30, 0))
    create_retrieval

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Request 1:')
    expect(messages_for(result)).to include(a_string_matching(/made before Inferno first returned/))
  end

  it 'reports every resumed request with an invalid changedsince' do
    create_retrieval
    create_resumed_request('2026-11-04T20:10:00Z')
    create_resumed_request('2026-11-04T20:31:30Z')
    create_resumed_request('not-a-time')

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Requests 3 and 4:')
  end
end
