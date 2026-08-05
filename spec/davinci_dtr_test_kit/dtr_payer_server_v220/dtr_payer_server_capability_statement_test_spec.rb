RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::DTRPayerServerCapabilityStatementTest, :runnable do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:server_endpoint) { 'http://example.com/fhir' }

  let(:test) do
    Class.new(described_class) do
      fhir_client { url :server_endpoint }

      input :server_endpoint
    end
  end

  def capability_statement(instantiates: [])
    {
      resourceType: 'CapabilityStatement',
      status: 'active',
      kind: 'instance',
      fhirVersion: '4.0.1',
      format: ['json'],
      instantiates:
    }.to_json
  end

  def stub_capability_statement(body)
    stub_request(:get, "#{server_endpoint}/metadata")
      .to_return(
        status: 200,
        body:,
        headers: { 'Content-Type' => 'application/fhir+json' }
      )
  end

  described_class::SUPPORTED_DTR_CAPABILITY_STATEMENTS.each do |canonical_url|
    it "passes when the CapabilityStatement declares #{canonical_url}" do
      stub_capability_statement(
        capability_statement(instantiates: [canonical_url])
      )

      result = run(test, server_endpoint:)

      expect(result.result).to eq('pass')
    end
  end

  it 'passes when the CapabilityStatement declares a versioned supported canonical' do
    stub_capability_statement(
      capability_statement(
        instantiates: [
          'http://hl7.org/fhir/us/davinci-dtr/CapabilityStatement/' \
          'dtr-payer-service|2.2.0'
        ]
      )
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('pass')
  end

  it 'fails when the CapabilityStatement does not declare a supported DTR configuration' do
    stub_capability_statement(
      capability_statement(
        instantiates: [
          'http://example.org/CapabilityStatement/not-a-dtr-configuration'
        ]
      )
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result.result_message).to eq(
      'CapabilityStatement does not declare conformance to a supported DTR ' \
      'CapabilityStatement. Expected one of: ' \
      "#{described_class::SUPPORTED_DTR_CAPABILITY_STATEMENTS.join(', ')}."
    )
  end

  it 'fails when the CapabilityStatement does not declare conformance to any configuration' do
    stub_capability_statement(capability_statement)

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
  end
end
