RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::SmallValueSetExpansionTest do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def store_response(response_body)
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(
      :request,
      result_id: result.id,
      test_session_id: test_session.id,
      response_body:,
      tags: [DaVinciDTRTestKit::VALUE_SET_EXPAND_TAG]
    )
  end

  def expanded_value_set(timestamp: Date.current.iso8601, inactive: false)
    FHIR::ValueSet.new(
      status: 'active',
      expansion: FHIR::ValueSet::Expansion.new(
        timestamp:,
        contains: [FHIR::ValueSet::Expansion::Contains.new(code: 'example', inactive:)]
      )
    )
  end

  it 'passes when a small ValueSet expansion uses the current date' do
    store_response(expanded_value_set.to_json)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails for an expansion with an outdated timestamp' do
    store_response(expanded_value_set(timestamp: (Date.current - 1).iso8601).to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expected_error = 'Small ValueSet expansion is not using current date'
    expect(result_messages.map(&:message).join).to include("(Request 1) #{expected_error}")
  end

  it 'fails when any returned ValueSet does not contain an expansion' do
    store_response(expanded_value_set.to_json)
    store_response(FHIR::ValueSet.new(status: 'active').to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join)
      .to match(/\(Request \d+\) ValueSet response does not contain an expansion\./)
  end

  it 'fails when a ValueSet/$expand request does not return a ValueSet' do
    store_response(FHIR::OperationOutcome.new.to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join)
      .to include('(Request 1) ValueSet/$expand response is not a ValueSet resource.')
  end

  it 'skips when no ValueSet/$expand requests were made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(%r{No ValueSet/\$expand requests were made})
  end
end
