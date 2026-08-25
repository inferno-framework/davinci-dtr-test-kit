require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/' \
        'dtr_server_questionnaire_package_contents_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::DTRServerQuestionnairePackageContentsTest,
               :runnable do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:create_prior_questionnaire_package_exchange) { true }
  let(:results_repo) { Inferno::Repositories::Results.new }

  let(:test) do
    Class.new(described_class) do
      id :dtr_server_v220_payer_questionnaire_package_contents_spec
    end
  end

  let(:questionnaire_package_body) do
    questionnaire_package_parameters(
      package_bundles: [
        package_bundle(entries: [questionnaire])
      ]
    )
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test) unless tests_repo.exists?(test.id.to_s)

    create_tagged_questionnaire_package_exchange if create_prior_questionnaire_package_exchange
  end

  def questionnaire
    {
      resourceType: 'Questionnaire',
      status: 'active'
    }
  end

  def package_bundle(entries:)
    {
      resourceType: 'Bundle',
      type: 'collection',
      entry: entries.map do |entry_resource|
        {
          resource: entry_resource
        }
      end
    }
  end

  def questionnaire_package_parameters(package_bundles:)
    {
      resourceType: 'Parameters',
      parameter: package_bundles.map do |package_bundle|
        {
          name: 'packagebundle',
          resource: package_bundle
        }
      end
    }.to_json
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [test])
      .first&.messages || []
  end

  def create_tagged_questionnaire_package_exchange(body: questionnaire_package_body)
    prior_result = repo_create(:result, test_session_id: test_session.id)

    repo_create(
      :request,
      result_id: prior_result.id,
      name: 'questionnaire_package',
      url: "#{server_endpoint}/Questionnaire/$questionnaire-package",
      request_body: {
        resourceType: 'Parameters'
      }.to_json,
      response_body: body,
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )
  end

  it 'passes when each Bundle starts with a Questionnaire' do
    result = run(test)

    expect(result.result).to eq('pass')
  end

  context 'when the questionnaire-package response is not valid JSON' do
    let(:questionnaire_package_body) { 'not valid JSON' }

    it 'omits' do
      result = run(test)

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq(
        'No valid questionnaire-package response Bundles were found.'
      )
    end
  end

  context 'when the questionnaire-package response is not Parameters' do
    let(:questionnaire_package_body) do
      {
        resourceType: 'OperationOutcome',
        issue: []
      }.to_json
    end

    it 'omits' do
      result = run(test)

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq(
        'No valid questionnaire-package response Bundles were found.'
      )
    end
  end

  context 'when the response does not contain a packagebundle parameter' do
    let(:questionnaire_package_body) do
      questionnaire_package_parameters(package_bundles: [])
    end

    it 'omits' do
      result = run(test)

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq(
        'No valid questionnaire-package response Bundles were found.'
      )
    end
  end

  context 'when the first Bundle entry is not a Questionnaire' do
    let(:questionnaire_package_body) do
      questionnaire_package_parameters(
        package_bundles: [
          package_bundle(
            entries: [
              {
                resourceType: 'Library',
                status: 'active'
              }
            ]
          )
        ]
      )
    end

    it 'fails' do
      result = run(test)

      expect(result.result).to eq('fail')
      expect(result.result_message).to include(
        'Not all questionnaire-package Bundles included the Questionnaire as the first entry.'
      )
      expect(result_messages.map(&:message).join("\n")).to include(
        'Unexpected resource type: expected Questionnaire, but received Library'
      )
    end
  end

  context 'when no prior questionnaire-package request is available' do
    let(:create_prior_questionnaire_package_exchange) { false }

    it 'skips the test' do
      result = run(test)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No $questionnaire-package requests were made in the Request Questionnaires test.'
      )
    end
  end

  context 'when an earlier questionnaire-package result is not valid JSON' do
    let(:create_prior_questionnaire_package_exchange) { false }

    before do
      create_tagged_questionnaire_package_exchange(body: 'not valid JSON')
      create_tagged_questionnaire_package_exchange
    end

    it 'skips the invalid result and passes when a later valid Bundle is present' do
      result = run(test)

      expect(result.result).to eq('pass')
    end
  end
end
