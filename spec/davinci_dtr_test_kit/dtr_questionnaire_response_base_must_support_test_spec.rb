RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnaireResponseBaseMustSupportTest do # rubocop:disable RSpec/SpecFilePathFormat
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

  # One answer for each choice type allowed on QuestionnaireResponse.item.answer.value[x]. The
  # boolean is deliberately `false` so the check has to credit a populated-but-falsy value.
  def answers_of_every_type
    [
      { valueBoolean: false },
      { valueDecimal: 1.5 },
      { valueInteger: 2 },
      { valueDate: '2024-01-01' },
      { valueDateTime: '2024-01-01T00:00:00Z' },
      { valueTime: '12:00:00' },
      { valueString: 'text' },
      { valueUri: 'http://example.org/uri' },
      { valueAttachment: { contentType: 'text/plain', data: 'aGk=' } },
      { valueCoding: { system: 'http://example.org/CodeSystem/answers', code: 'yes' } },
      { valueQuantity: { value: 1, unit: 'mg' } },
      { valueReference: { reference: 'Patient/1' } }
    ]
  end

  def questionnaire_display_extension
    { extension: [{ url: 'http://hl7.org/fhir/StructureDefinition/display', valueString: 'Adaptive Form' }] }
  end

  # Built as a plain Hash so the `_questionnaire` primitive extension (questionnaireDisplay) survives
  # serialization: fhir_models only carries primitive extensions in its parse-time `source_hash`.
  # Root-level conf-5 elements can be dropped through `overrides` (eg `authored: nil`).
  def questionnaire_response_hash(items, include_display: true, **overrides)
    {
      resourceType: 'QuestionnaireResponse',
      status: 'in-progress',
      questionnaire: 'http://example.org/Questionnaire/adaptive|1.0.0',
      _questionnaire: include_display ? questionnaire_display_extension : nil,
      authored: '2024-01-01T00:00:00Z',
      author: { reference: 'Practitioner/1' },
      item: items
    }.merge(overrides).compact
  end

  def conformant_items
    [{ linkId: 'Q1', text: 'Question one', answer: answers_of_every_type }]
  end

  def bare_body(questionnaire_response)
    questionnaire_response.to_json
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

  it 'ignores requests that are not tagged as $next-question requests' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items)),
                      request_tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])

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

  it 'passes when a bare QuestionnaireResponse populates every conf-5 element and answer type' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items)))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'extracts the QuestionnaireResponse from a Parameters request body' do
    create_nq_request(parameters_body(questionnaire_response_hash(conformant_items)))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails naming the missing element when a conf-5 element is never populated' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items, authored: nil)))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Could not find authored in')
  end

  it 'fails naming the missing extension when questionnaireDisplay is never populated' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items, include_display: false)))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message)
      .to include('Could not find QuestionnaireResponse.questionnaire.extension:questionnaireDisplay in')
  end

  it 'fails naming the missing type when one answer choice type is never used' do
    answers = answers_of_every_type.reject { |answer| answer.key?(:valueAttachment) }
    create_nq_request(bare_body(questionnaire_response_hash([{ linkId: 'Q1', text: 'Q', answer: answers }])))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Could not find item.answer.valueAttachment in')
  end

  it 'accumulates coverage across several requests when no single QuestionnaireResponse has everything' do
    first_half, second_half = answers_of_every_type.each_slice(6).to_a
    create_nq_request(bare_body(questionnaire_response_hash([{ linkId: 'Q1', text: 'Question one' }],
                                                            include_display: false, author: nil)))
    create_nq_request(bare_body(questionnaire_response_hash([{ linkId: 'Q1', answer: first_half }], authored: nil)))
    create_nq_request(parameters_body(questionnaire_response_hash([{ linkId: 'Q1', answer: second_half }],
                                                                  include_display: false, author: nil, authored: nil)))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  describe 'nested items' do
    # Demonstrates everything except item.text and a string answer on a flat response, so the
    # outcome hinges on whether the deeply nested text and answer are credited.
    def flat_body_without_text_or_string_answer
      answers = answers_of_every_type.reject { |answer| answer.key?(:valueString) }
      bare_body(questionnaire_response_hash([{ linkId: 'Q1', answer: answers }]))
    end

    def deepest_item
      { linkId: 'Q1.1.1', text: 'Deep question', answer: [{ valueString: 'deep' }] }
    end

    it 'credits item.text and an answer type that appear only three levels deep under item.item' do
      items = [{ linkId: 'G1', item: [{ linkId: 'G1.1', item: [deepest_item] }] }]
      create_nq_request(flat_body_without_text_or_string_answer)
      create_nq_request(bare_body(questionnaire_response_hash(items)))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'credits item.text and an answer type that appear only three levels deep under item.answer.item' do
      items = [{ linkId: 'Q1',
                 answer: [{ valueBoolean: true,
                            item: [{ linkId: 'Q1.1', answer: [{ valueBoolean: true, item: [deepest_item] }] }] }] }]
      create_nq_request(flat_body_without_text_or_string_answer)
      create_nq_request(bare_body(questionnaire_response_hash(items)))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'credits nested items reached through a mix of item.item and item.answer.item' do
      items = [{ linkId: 'G1', item: [{ linkId: 'Q1.1', answer: [{ valueBoolean: true, item: [deepest_item] }] }] }]
      create_nq_request(flat_body_without_text_or_string_answer)
      create_nq_request(bare_body(questionnaire_response_hash(items)))

      result = run(described_class)

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'still fails when no item at any depth populates the element' do
      textless_deep_item = { linkId: 'Q1.1.1', answer: [{ valueString: 'deep' }] }
      items = [{ linkId: 'Q1', answer: [{ valueBoolean: true, item: [textless_deep_item] }] }]
      create_nq_request(flat_body_without_text_or_string_answer)
      create_nq_request(bare_body(questionnaire_response_hash(items)))

      result = run(described_class)

      expect(result.result).to eq('fail')
      expect(result.result_message).to include('Could not find item.text in')
    end
  end
end
