# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/next_question_support/invalid_questionnaire_response_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::InvalidQuestionnaireResponseTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:url) { 'https://payer.example.com/fhir' }
  let(:operation_url) { "#{url}/Questionnaire/$next-question" }

  let(:test_class) do
    Class.new(described_class) do
      id :dtr_v220_payer_invalid_questionnaire_response_spec

      input :url
      input :backend_services_smart_auth_info, optional: true

      fhir_client do
        url :url
        auth_info :backend_services_smart_auth_info
      end
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)
  end

  def invalid_questionnaire_response
    FHIR::QuestionnaireResponse.new(
      status: 'in-progress',
      contained: [
        FHIR::Questionnaire.new(
          id: 'invalid-questionnaire',
          status: 'draft',
          item: [FHIR::Questionnaire::Item.new(linkId: 'required-item', type: 'string', required: true)]
        )
      ],
      questionnaire: '#invalid-questionnaire'
    ).to_json
  end

  def operation_outcome(issues: true)
    issue = if issues
              [FHIR::OperationOutcome::Issue.new(
                severity: 'error',
                code: 'invalid',
                diagnostics: 'The required item has no answer.'
              )]
            else
              []
            end

    FHIR::OperationOutcome.new(issue:).to_json
  end

  def stub_response(status:, body: operation_outcome)
    stub_request(:post, operation_url)
      .to_return(status:, body:, headers: { 'Content-Type' => 'application/fhir+json' })
  end

  it 'passes when the server returns 400 with an OperationOutcome containing an issue' do
    stub_response(status: 400)

    result = run(test_class, url:, invalid_questionnaire_response:)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when the server returns a 4xx status other than 400' do
    stub_response(status: 422)

    result = run(test_class, url:, invalid_questionnaire_response:)

    expect(result.result).to eq('fail')
  end

  it 'fails when the response is not an OperationOutcome' do
    stub_response(status: 400, body: FHIR::QuestionnaireResponse.new(status: 'in-progress').to_json)

    result = run(test_class, url:, invalid_questionnaire_response:)

    expect(result.result).to eq('fail')
  end

  it 'fails when the OperationOutcome does not contain an issue' do
    stub_response(status: 400, body: operation_outcome(issues: false))

    result = run(test_class, url:, invalid_questionnaire_response:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('did not include an issue')
  end

  it 'fails before making a request when the input is not a QuestionnaireResponse' do
    result = run(test_class, url:, invalid_questionnaire_response: FHIR::Questionnaire.new(status: 'draft').to_json)

    expect(result.result).to eq('fail')
    expect(WebMock).to_not have_requested(:post, operation_url)
  end
end
