# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/value_set_expand_support/value_set_expansion_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ValueSetExpansionTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }

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

  it 'passes for a current expansion containing only active codes' do
    store_response(expanded_value_set.to_json)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails for an expansion with an outdated timestamp' do
    store_response(expanded_value_set(timestamp: (Date.current - 1).iso8601).to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expected_error = "expansion.timestamp `#{Date.current - 1}` is not the current date `#{Date.current}`"
    expect(result.result_message).to include(expected_error)
  end

  it 'fails for an expansion containing an inactive code' do
    store_response(expanded_value_set(inactive: true).to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/expansion contains inactive code/)
  end

  it 'skips when no expanded ValueSet was returned' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No expanded ValueSet resources were returned/)
  end
end
