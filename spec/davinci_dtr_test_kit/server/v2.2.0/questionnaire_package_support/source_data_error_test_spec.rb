# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/source_data_error_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::SourceDataErrorTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:url) { 'https://payer.example.com/fhir' }
  let(:operation_url) { "#{url}/Questionnaire/$questionnaire-package" }

  let(:test_class) do
    Class.new(described_class) do
      id :dtr_v220_payer_source_data_error_spec

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

  def source_data_error_request
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'context', valueString: 'unknown-context')]
    ).to_json
  end

  def operation_outcome
    FHIR::OperationOutcome.new(
      issue: [
        FHIR::OperationOutcome::Issue.new(
          severity: 'error',
          code: 'not-found',
          diagnostics: 'The supplied context identifier could not be found.'
        )
      ]
    ).to_json
  end

  def stub_response(status:, body: operation_outcome)
    stub_request(:post, operation_url)
      .to_return(status:, body:, headers: { 'Content-Type' => 'application/fhir+json' })
  end

  it 'passes when the server returns a 4xx response with an OperationOutcome' do
    stub_response(status: 422)

    result = run(test_class, url:, source_data_error_request:)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when the server returns a status outside the 4xx range' do
    stub_response(status: 500)

    result = run(test_class, url:, source_data_error_request:)

    expect(result.result).to eq('fail')
  end

  it 'fails when the response is not an OperationOutcome' do
    stub_response(status: 400, body: FHIR::Parameters.new.to_json)

    result = run(test_class, url:, source_data_error_request:)

    expect(result.result).to eq('fail')
  end

  it 'fails before making a request when the input is not a Parameters resource' do
    result = run(test_class, url:, source_data_error_request: FHIR::Questionnaire.new(status: 'draft').to_json)

    expect(result.result).to eq('fail')
    expect(WebMock).to_not have_requested(:post, operation_url)
  end
end
