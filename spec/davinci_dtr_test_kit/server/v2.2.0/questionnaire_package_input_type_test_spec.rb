RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnairePackageInputTypeTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:canonical_param) do
    {
      name: 'questionnaire',
      valueCanonical: 'ABC'
    }
  end
  let(:context_param) do
    {
      name: 'context',
      valueString: 'DEF'
    }
  end
  let(:order_param) do
    {
      name: 'order',
      resource: [{ resourceType: 'Appointment' }]
    }
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def stub_requests(params)
    requests = params.map { |param| repo_create(:request, request_body: param.to_json) }

    allow_any_instance_of(described_class).to receive(:requests).and_return(requests)
  end

  it 'passes if all input types are provided' do
    params = [
      FHIR::Parameters.new(parameter: [canonical_param]),
      FHIR::Parameters.new(parameter: [context_param]),
      FHIR::Parameters.new(parameter: [order_param])
    ]

    stub_requests(params)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails if a canonical is not provided by itself' do
    params = [
      FHIR::Parameters.new(parameter: [canonical_param, context_param]),
      FHIR::Parameters.new(parameter: [context_param]),
      FHIR::Parameters.new(parameter: [order_param])
    ]

    stub_requests(params)

    result = run(described_class)

    expect(result.result).to eq('fail'), result.result_message
    expect(result.result_message).to include('Not all required $questionnaire-package input')
    expect(result_messages.first.message).to include('canonical')
  end

  it 'fails if a context id is not provided by itself' do
    params = [
      FHIR::Parameters.new(parameter: [canonical_param]),
      FHIR::Parameters.new(parameter: [context_param, order_param]),
      FHIR::Parameters.new(parameter: [order_param])
    ]

    stub_requests(params)

    result = run(described_class)

    expect(result.result).to eq('fail'), result.result_message
    expect(result.result_message).to include('Not all required $questionnaire-package input')
    expect(result_messages.first.message).to include('context id')
  end

  it 'fails if an order resource is not provided by itself' do
    params = [
      FHIR::Parameters.new(parameter: [canonical_param]),
      FHIR::Parameters.new(parameter: [context_param]),
      FHIR::Parameters.new(parameter: [order_param, canonical_param])
    ]

    stub_requests(params)

    result = run(described_class)

    expect(result.result).to eq('fail'), result.result_message
    expect(result.result_message).to include('Not all required $questionnaire-package input')
    expect(result_messages.first.message).to include('order resource')
  end

  it 'fails if a non-Paramaters resource is provided' do
    params = [
      FHIR::Parameters.new(parameter: [canonical_param]),
      FHIR::Parameters.new(parameter: [context_param]),
      FHIR::Parameters.new(parameter: [order_param]),
      FHIR::Observation.new
    ]

    stub_requests(params)

    result = run(described_class)

    expect(result.result).to eq('fail'), result.result_message
    expect(result.result_message).to eq('Not all provided request bodies were Parameters resources.')
  end

  it 'skips if no valid request bodies are provided' do
    request = repo_create(:request, request_body: 'ABC')
    allow_any_instance_of(described_class).to receive(:requests).and_return([request])

    result = run(described_class)

    expect(result.result).to eq('skip'), result.result_message
    expect(result.result_message).to eq('No valid request bodies were provided.')
  end
end
