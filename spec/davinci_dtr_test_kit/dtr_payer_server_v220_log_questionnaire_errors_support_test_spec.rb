require 'davinci_dtr_test_kit/server/v2.2.0/log_questionnaire_errors_support_test'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::LogQuestionnaireErrorsSupportTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:url) { 'https://payer.example.com/fhir' }
  let(:operation_url) { "#{url}/Questionnaire/$log-questionnaire-errors" }
  let(:test_class) do
    Class.new(described_class) do
      id :dtr_v220_payer_log_questionnaire_errors_support_spec

      fhir_client { url :url }
    end
  end

  before do
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(test_class) unless tests_repo.exists?(test_class.id.to_s)
  end

  it 'passes when the payer returns a 2xx response' do
    stub_request(:post, operation_url).to_return(status: 200)

    result = run(test_class, url:)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'posts a conformant representative error report to the operation endpoint' do
    stub_request(:post, operation_url).to_return(status: 204)

    result = run(test_class, url:)

    expect(result.result).to eq('pass'), result.result_message
    expect(WebMock).to have_requested(:post, operation_url)

    request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.find do |signature|
      signature.method == :post
    end
    parameters = JSON.parse(request.body)
    expect(parameters).to include(
      'resourceType' => 'Parameters'
    )
    expect(parameters['parameter']).to include(
      a_hash_including('name' => 'questionnaire', 'valueCanonical' => a_kind_of(String)),
      a_hash_including(
        'name' => 'operationOutcome',
        'resource' => a_hash_including(
          'resourceType' => 'OperationOutcome',
          'issue' => a_collection_including(
            a_hash_including('severity' => a_kind_of(String), 'code' => a_kind_of(String))
          )
        )
      )
    )
  end

  [400, 500].each do |status|
    it "fails when the payer returns HTTP #{status}" do
      stub_request(:post, operation_url).to_return(status:, body: FHIR::OperationOutcome.new.to_json)

      result = run(test_class, url:)

      expect(result.result).to eq('fail')
      expect(result.result_message).to include("received HTTP #{status}")
    end
  end

  it 'fails when no request record is returned' do
    allow_any_instance_of(test_class).to receive(:fhir_operation).and_return(nil)

    result = run(test_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('No request record was returned')
  end

  it 'fails when the request record has no HTTP response' do
    allow_any_instance_of(test_class).to receive(:fhir_operation).and_return(double(response: nil))

    result = run(test_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('No HTTP response was received')
  end
end
