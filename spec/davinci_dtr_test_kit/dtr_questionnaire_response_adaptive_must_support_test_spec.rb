RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnaireResponseAdaptiveMustSupportTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:tags) { [DaVinciDTRTestKit::CLIENT_NEXT_TAG] }

  def create_nq_request(request_body, request_tags: tags)
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
      test_session_id: test_session.id,
      result:,
      request_body:,
      tags: request_tags,
      status: 200
    )
  end

  def contained_adaptive_questionnaire
    {
      resourceType: 'Questionnaire',
      id: 'adaptive',
      url: 'http://example.org/Questionnaire/adaptive',
      status: 'active',
      extension: [
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueBoolean: true }
      ],
      item: [{ linkId: 'Q1', type: 'string' }]
    }
  end

  # Satisfies dtr_questionnaireresponse_adapt's single must support (a differential of
  # dtr_questionnaireresponse): the contained adaptive Questionnaire.
  def questionnaire_response_hash(contained: [contained_adaptive_questionnaire])
    {
      resourceType: 'QuestionnaireResponse',
      status: 'in-progress',
      questionnaire: '#adaptive',
      contained:,
      item: [{ linkId: 'Q1', answer: [{ valueString: 'answer' }] }]
    }.compact
  end

  def parameters_body(questionnaire_response)
    {
      resourceType: 'Parameters',
      parameter: [{ name: 'questionnaire-response', resource: questionnaire_response }]
    }.to_json
  end

  it 'skips when no $next-question requests have been made' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('Requests must be made')
  end

  it 'skips when no tagged request body contains a QuestionnaireResponse' do
    create_nq_request({ resourceType: 'Parameters', parameter: [{ name: 'other', valueString: 'x' }] }.to_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No QuestionnaireResponses found')
  end

  it 'skips rather than raising when a request body is not valid JSON' do
    create_nq_request('not valid json')

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No QuestionnaireResponses found')
  end

  it 'fails naming contained when no QuestionnaireResponse contains its adaptive Questionnaire' do
    create_nq_request(questionnaire_response_hash(contained: nil).to_json)

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Could not find contained in')
  end

  it 'passes when a bare QuestionnaireResponse contains its adaptive Questionnaire' do
    create_nq_request(questionnaire_response_hash.to_json)

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'extracts the QuestionnaireResponse from a Parameters request body' do
    create_nq_request(parameters_body(questionnaire_response_hash))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'passes when only one of several requests contains the adaptive Questionnaire' do
    create_nq_request(questionnaire_response_hash(contained: nil).to_json)
    create_nq_request(parameters_body(questionnaire_response_hash))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end
end
