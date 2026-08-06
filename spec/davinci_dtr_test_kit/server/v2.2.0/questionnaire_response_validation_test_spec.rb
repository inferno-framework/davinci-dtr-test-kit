RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireResponseValidationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:url) { 'https://payer.example.com/fhir' }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  it 'skips if no requests have been made' do
    result = run(described_class, url:)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No $questionnaire-package')
  end

  it 'fails if no successful requests have been made' do
    request = repo_create(:request, status: 400, response_body: '{}')

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('was unsuccessful')
  end

  it 'fails if a response contains invalid JSON' do
    request = repo_create(:request)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('invalid JSON')
  end

  it 'fails if a response does not contain a FHIR resource' do
    request = repo_create(:request, response_body: '{}')

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('did not contain FHIR resources')
  end

  it 'fails if the response does not conform to the profile' do
    parameters =
      FHIR::Parameters.new(
        parameter: [
          {
            name: 'packagebundle',
            resource: FHIR::Bundle.new
          }
        ]
      )
    request = repo_create(:request, response_body: parameters.to_json)
    error_message = { type: 'error', message: 'validation error' }

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(false)
    allow_any_instance_of(described_class).to receive(:messages).and_return([error_message])

    result = run(described_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('validation error')
  end

  it 'fails if the response does not contain a Bundle' do
    parameters = FHIR::Parameters.new
    request = repo_create(:request, response_body: parameters.to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)

    result = run(described_class, url:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Not all responses were valid')

    expect(result_messages.first.message).to include('No Questionnaire Bundle')
  end

  it 'passes if a valid response is returned' do
    parameters =
      FHIR::Parameters.new(
        parameter: [
          {
            name: 'packagebundle',
            resource: FHIR::Bundle.new
          }
        ]
      )
    request = repo_create(:request, response_body: parameters.to_json)

    allow_any_instance_of(described_class).to receive(:requests).and_return([request])
    allow_any_instance_of(described_class).to receive(:resource_is_valid?).and_return(true)

    result = run(described_class, url:)

    expect(result.result).to eq('pass')
  end
end
