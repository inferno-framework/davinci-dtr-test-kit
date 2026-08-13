RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::DTRPayerServerCapabilityStatementTest, :runnable do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:results_repo) { Inferno::Repositories::Results.new }

  let(:test) do
    Class.new(described_class) do
      fhir_client { url :server_endpoint }

      input :server_endpoint
    end
  end

  before do
    allow_any_instance_of(test).to receive(:assert_valid_resource).and_return(true)
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [test])
      .first&.messages || []
  end

  def capability_statement(
    questionnaire_operations: [
      'questionnaire-package',
      'next-question',
      'log-questionnaire-errors'
    ],
    value_set_operations: ['expand'],
    questionnaire_resource: true,
    value_set_resource: true,
    server_rest: true
  )
    resources = []

    if questionnaire_resource
      resources << {
        type: 'Questionnaire',
        operation: questionnaire_operations.map { |name| { name: } }
      }
    end

    if value_set_resource
      resources << {
        type: 'ValueSet',
        operation: value_set_operations.map { |name| { name: } }
      }
    end

    rest = []

    if server_rest
      rest << {
        mode: 'server',
        resource: resources
      }
    end

    {
      resourceType: 'CapabilityStatement',
      status: 'active',
      kind: 'instance',
      date: '2026-01-01',
      implementation: {
        description: 'Example payer server'
      },
      fhirVersion: '4.0.1',
      format: ['json'],
      rest:
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

  it 'passes when the CapabilityStatement declares all required DTR Payer Service operations' do
    stub_capability_statement(capability_statement)

    result = run(test, server_endpoint:)

    expect(result.result).to eq('pass')
  end

  it 'fails when the CapabilityStatement has no server-mode rest entry' do
    stub_capability_statement(
      capability_statement(server_rest: false)
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message)).to include(
      'CapabilityStatement is missing a `rest` entry with `mode` set to `server`.'
    )
  end

  it 'fails when the CapabilityStatement does not declare a Questionnaire resource' do
    stub_capability_statement(
      capability_statement(questionnaire_resource: false)
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message)).to include(
      'CapabilityStatement is missing a `Questionnaire` resource entry ' \
      'in its server-mode `rest` section.'
    )
  end

  it 'fails when the CapabilityStatement does not declare a ValueSet resource' do
    stub_capability_statement(
      capability_statement(value_set_resource: false)
    )

    result = run(test, server_endpoint:)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message)).to include(
      'CapabilityStatement is missing a `ValueSet` resource entry ' \
      'in its server-mode `rest` section.'
    )
  end

  described_class::REQUIRED_RESOURCE_OPERATIONS.each do |resource_type, required_operations|
    required_operations.each do |operation|
      it "fails when the CapabilityStatement is missing #{resource_type}/$#{operation}" do
        questionnaire_operations = [
          'questionnaire-package',
          'next-question',
          'log-questionnaire-errors'
        ]
        value_set_operations = ['expand']

        if resource_type == 'Questionnaire'
          questionnaire_operations -= [operation]
        else
          value_set_operations -= [operation]
        end

        stub_capability_statement(
          capability_statement(
            questionnaire_operations:,
            value_set_operations:
          )
        )

        result = run(test, server_endpoint:)

        expect(result.result).to eq('fail')
        expect(result_messages.map(&:message)).to include(
          "CapabilityStatement is missing required `#{resource_type}` operations: $#{operation}."
        )
      end
    end
  end
end
