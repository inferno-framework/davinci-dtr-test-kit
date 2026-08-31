RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::SmallValueSetExpansionTest do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:canonical) { 'http://example.org/ValueSet/example|1.0.0' }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def store_questionnaire_package_response(value_set)
    bundle = FHIR::Bundle.new(entry: [{ resource: value_set }])
    parameters = FHIR::Parameters.new(
      parameter: [{ name: 'packagebundle', resource: bundle }]
    )

    repo_create(
      :request,
      result_id: result.id,
      test_session_id: test_session.id,
      response_body: parameters.to_json,
      status: 200,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )
  end

  def store_expand_response(entry_count:)
    request_parameters = FHIR::Parameters.new(
      parameter: [{ name: 'url', valueUri: canonical }]
    )
    expanded_value_set = FHIR::ValueSet.new(
      expansion: {
        contains: Array.new(entry_count) { |index| { code: "code-#{index}" } }
      }
    )

    repo_create(
      :request,
      result_id: result.id,
      test_session_id: test_session.id,
      request_body: request_parameters.to_json,
      response_body: expanded_value_set.to_json,
      status: 200,
      tags: [DaVinciDTRTestKit::VALUE_SET_EXPAND_TAG]
    )
  end

  def package_value_set(expansion: nil, compose: nil)
    FHIR::ValueSet.new(
      url: 'http://example.org/ValueSet/example',
      version: '1.0.0',
      status: 'active',
      expansion:,
      compose:
    )
  end

  it 'fails when a small ValueSet is not expanded in the questionnaire-package response' do
    store_questionnaire_package_response(package_value_set)
    store_expand_response(entry_count: 39)

    test_result = run(described_class)

    expect(test_result.result).to eq('fail')
    expect(result_messages.map(&:message).join)
      .to include("Small ValueSet `#{canonical}` is not expanded")
  end

  it 'passes when a small ValueSet has a current expansion in the questionnaire-package response' do
    expansion = {
      timestamp: Date.current.iso8601,
      contains: [{ code: 'example' }]
    }
    store_questionnaire_package_response(package_value_set(expansion:))
    store_expand_response(entry_count: 39)

    test_result = run(described_class)

    expect(test_result.result).to eq('pass'), test_result.result_message
  end

  it 'fails when a small ValueSet has an outdated expansion timestamp' do
    expansion = {
      timestamp: (Date.current - 1).iso8601,
      contains: [{ code: 'example' }]
    }
    store_questionnaire_package_response(package_value_set(expansion:))
    store_expand_response(entry_count: 39)

    test_result = run(described_class)

    expect(test_result.result).to eq('fail')
    expect(result_messages.map(&:message).join)
      .to include("expansion.timestamp `#{Date.current - 1}` is not the current date `#{Date.current}`")
  end

  it 'passes when the matching expansion contains at least 40 entries' do
    store_questionnaire_package_response(package_value_set)
    store_expand_response(entry_count: 40)

    test_result = run(described_class)

    expect(test_result.result).to eq('pass'), test_result.result_message
  end

  it 'skips when no $questionnaire-package requests were made' do
    test_result = run(described_class)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No $questionnaire-package requests were made')
  end
end
