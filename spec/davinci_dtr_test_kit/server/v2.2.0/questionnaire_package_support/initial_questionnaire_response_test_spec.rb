# frozen_string_literal: true

require(
  'davinci_dtr_test_kit/server/v2.2.0/questionnaire_package_support/initial_questionnaire_response_test'
)

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::InitialQuestionnaireResponseTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  def store_response(questionnaire_response, request_body: nil)
    result = repo_create(:result, test_session_id: test_session.id)
    bundle = FHIR::Bundle.new(
      type: 'collection',
      entry: [
        FHIR::Bundle::Entry.new(resource: FHIR::Questionnaire.new(status: 'draft')),
        FHIR::Bundle::Entry.new(resource: questionnaire_response)
      ]
    )
    parameters = FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)]
    )
    repo_create(:request, result_id: result.id, test_session_id: test_session.id, request_body:,
                          response_body: parameters.to_json, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])
  end

  def request_parameters(include_order: true, order_resource: nil)
    parameters = [
      FHIR::Parameters::Parameter.new(
        name: 'coverage',
        resource: FHIR::Coverage.new(
          id: 'example',
          beneficiary: FHIR::Reference.new(reference: 'Patient/example')
        )
      )
    ]
    if include_order
      parameters << FHIR::Parameters::Parameter.new(
        name: 'order', resource: order_resource || FHIR::ServiceRequest.new(id: 'example', status: 'draft')
      )
    end

    FHIR::Parameters.new(
      parameter: parameters
    ).to_json
  end

  def questionnaire_response(attributes = {})
    FHIR::QuestionnaireResponse.new({
      status: 'in-progress',
      subject: FHIR::Reference.new(reference: 'Patient/example'),
      extension: [
        FHIR::Extension.new(
          url: described_class::COVERAGE_EXTENSION_URL,
          valueReference: FHIR::Reference.new(reference: 'Coverage/example')
        ),
        FHIR::Extension.new(
          url: described_class::CONTEXT_EXTENSION_URL,
          valueReference: FHIR::Reference.new(reference: 'ServiceRequest/example')
        )
      ]
    }.merge(attributes))
  end

  it 'passes for an in-progress response with subject, coverage, and context' do
    store_response(questionnaire_response, request_body: request_parameters)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails when the response is not initial' do
    store_response(questionnaire_response(status: 'completed'))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join).to include('QuestionnaireResponse.status must be `in-progress`.')
  end

  it 'fails when the response subject is absent' do
    store_response(questionnaire_response(subject: nil), request_body: request_parameters)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join).to include('QuestionnaireResponse.subject must be populated.')
  end

  it 'fails when the coverage extension is absent' do
    response = questionnaire_response
    response.extension.reject! { |extension| extension.url == described_class::COVERAGE_EXTENSION_URL }
    store_response(response, request_body: request_parameters)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join).to include(
      'QuestionnaireResponse must include a qr-coverage extension.'
    )
  end

  it 'fails when the context extension is absent' do
    response = questionnaire_response
    response.extension.reject! { |extension| extension.url == described_class::CONTEXT_EXTENSION_URL }
    store_response(response, request_body: request_parameters)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join).to include('QuestionnaireResponse must include a qr-context extension.')
  end

  it 'requires context when the request contains an Encounter' do
    response = questionnaire_response
    response.extension.reject! { |extension| extension.url == described_class::CONTEXT_EXTENSION_URL }
    request_body = request_parameters(order_resource: FHIR::Encounter.new(id: 'example', status: 'planned'))
    store_response(response, request_body:)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result_messages.map(&:message).join).to include('QuestionnaireResponse must include a qr-context extension.')
  end

  it 'does not require a context extension when the request contains no order' do
    response = questionnaire_response
    response.extension.reject! { |extension| extension.url == described_class::CONTEXT_EXTENSION_URL }
    store_response(response, request_body: request_parameters(include_order: false))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'skips when no QuestionnaireResponse was returned' do
    response = FHIR::Parameters.new(
      parameter: [
        FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: FHIR::Bundle.new(type: 'collection'))
      ]
    )
    result = repo_create(:result, test_session_id: test_session.id)
    repo_create(:request, result_id: result.id, test_session_id: test_session.id,
                          response_body: response.to_json, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])

    test_result = run(described_class)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('response validation test verifies their presence')
  end
end
