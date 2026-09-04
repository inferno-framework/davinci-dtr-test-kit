require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/' \
        'dtr_server_questionnaire_not_found_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::DTRServerQuestionnaireNotFoundTest, :runnable do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:create_prior_questionnaire_request) { true }

  let(:test) do
    Class.new(described_class) do
      id :dtr_server_v220_payer_questionnaire_not_found_spec

      fhir_client { url :url }
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test) unless tests_repo.exists?(test.id.to_s)

    allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)

    create_tagged_questionnaire_package_request if create_prior_questionnaire_request
  end

  def questionnaire_package_request
    {
      resourceType: 'Parameters',
      parameter: [
        {
          name: 'coverage',
          resource: {
            resourceType: 'Coverage',
            status: 'active'
          }
        },
        {
          name: 'questionnaire',
          valueCanonical: 'https://example.com/Questionnaire/existing-questionnaire'
        }
      ]
    }.to_json
  end

  def create_tagged_questionnaire_package_request
    prior_result = repo_create(:result, test_session_id: test_session.id)

    repo_create(
      :request,
      result_id: prior_result.id,
      name: 'questionnaire_package',
      url: "#{server_endpoint}/Questionnaire/$questionnaire-package",
      request_body: questionnaire_package_request,
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )
  end

  def operation_outcome(issues: [])
    {
      resourceType: 'OperationOutcome',
      issue: issues
    }
  end

  def questionnaire_package_response(outcome: true, outcome_resource: operation_outcome)
    parameters = []

    if outcome
      parameters << {
        name: 'outcome',
        resource: outcome_resource
      }
    end

    {
      resourceType: 'Parameters',
      parameter: parameters
    }.to_json
  end

  def stub_questionnaire_package_response(body:)
    stub_request(
      :post,
      "#{server_endpoint}/Questionnaire/$questionnaire-package"
    ).to_return(
      status: 200,
      body:,
      headers: { 'Content-Type' => 'application/fhir+json' }
    )
  end

  it 'passes when the response contains an OperationOutcome warning' do
    stub_questionnaire_package_response(
      body: questionnaire_package_response(
        outcome_resource: operation_outcome(
          issues: [
            {
              severity: 'warning',
              code: 'not-found',
              diagnostics: 'Requested Questionnaire was not found.'
            }
          ]
        )
      )
    )

    result = run(test, url: server_endpoint)

    expect(result.result).to eq('pass')
    questionnaire_package_requests = Inferno::Repositories::Requests.new.tagged_requests(
      test_session.id,
      [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )
    expect(questionnaire_package_requests.length).to eq(2)
    expect(questionnaire_package_requests.last.response_body).to include('OperationOutcome')
    expect(
      a_request(
        :post,
        "#{server_endpoint}/Questionnaire/$questionnaire-package"
      ).with do |request|
        request_body = JSON.parse(request.body)

        request_body['parameter'].any? do |parameter|
          parameter['name'] == 'questionnaire' &&
            parameter['valueCanonical'] ==
              described_class::QUESTIONNAIRE_NOT_FOUND_URL
        end
      end
    ).to have_been_made
  end

  it 'fails when the questionnaire-package response is not Parameters' do
    stub_questionnaire_package_response(
      body: operation_outcome(
        issues: [
          {
            severity: 'warning',
            code: 'not-found'
          }
        ]
      ).to_json
    )

    result = run(test, url: server_endpoint)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'Unexpected resource type: expected Parameters, but received OperationOutcome'
    )
  end

  it 'fails when the response does not include an outcome parameter' do
    stub_questionnaire_package_response(
      body: questionnaire_package_response(outcome: false)
    )

    result = run(test, url: server_endpoint)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'The questionnaire-package response is missing the required `outcome` parameter.'
    )
  end

  it 'fails when the outcome parameter does not contain a resource' do
    stub_questionnaire_package_response(
      body: questionnaire_package_response(outcome_resource: nil)
    )

    result = run(test, url: server_endpoint)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'The `outcome` parameter does not contain an OperationOutcome resource.'
    )
  end

  it 'fails when the outcome parameter contains a resource other than an OperationOutcome' do
    stub_questionnaire_package_response(
      body: questionnaire_package_response(
        outcome_resource: {
          resourceType: 'Questionnaire',
          status: 'active'
        }
      )
    )

    result = run(test, url: server_endpoint)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'Unexpected resource type: expected OperationOutcome, but received Questionnaire'
    )
  end

  it 'fails when the OperationOutcome contains no warning issue' do
    stub_questionnaire_package_response(
      body: questionnaire_package_response(
        outcome_resource: operation_outcome(
          issues: [
            {
              severity: 'error',
              code: 'not-found'
            }
          ]
        )
      )
    )

    result = run(test, url: server_endpoint)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'The OperationOutcome in the `outcome` parameter does not contain a warning issue.'
    )
  end

  context 'when no prior questionnaire-package request is available' do
    let(:create_prior_questionnaire_request) { false }

    it 'skips the test' do
      result = run(test, url: server_endpoint)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq(
        'No $questionnaire-package requests were made in the Request Questionnaires test.'
      )
    end
  end
end
