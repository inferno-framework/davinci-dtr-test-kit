RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnaireResponseBaseMustSupportTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:tags) { [DaVinciDTRTestKit::CLIENT_NEXT_TAG] }

  let(:signature_url) { 'http://hl7.org/fhir/StructureDefinition/questionnaireresponse-signature' }
  let(:dtr_extension_base) { 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition' }

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

  def signature_extension
    {
      url: signature_url,
      valueSignature: {
        type: [{ system: 'urn:iso-astm:E1762-95:2013', code: '1.2.840.10065.1.12.1.1' }],
        when: '2024-01-01T00:00:00Z',
        who: { reference: 'Practitioner/1' }
      }
    }
  end

  def root_extensions(except: nil)
    extensions = {
      signature: signature_extension,
      coverage: { url: "#{dtr_extension_base}/qr-coverage", valueReference: { reference: 'Coverage/1' } },
      context: { url: "#{dtr_extension_base}/qr-context", valueReference: { reference: 'ServiceRequest/1' } },
      coverage_information: { url: 'http://hl7.org/fhir/us/davinci-crd/StructureDefinition/ext-coverage-information',
                              extension: [{ url: 'covered', valueCode: 'covered' }] },
      intended_use: { url: "#{dtr_extension_base}/intendedUse",
                      valueCodeableConcept: { coding: [{ code: 'withorder' }] } }
    }
    extensions.except(except).values
  end

  def answer_extensions
    [
      { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-itemAnswerMedia',
        valueAttachment: { contentType: 'image/png', url: 'http://example.org/image.png' } },
      { url: 'http://hl7.org/fhir/StructureDefinition/itemWeight', valueDecimal: 1.0 },
      { url: "#{dtr_extension_base}/information-origin", extension: [{ url: 'source', valueCode: 'manual' }] },
      { url: "#{dtr_extension_base}/containedReference", valueReference: { reference: '#contained' } }
    ]
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
  # Root-level elements can be dropped through `overrides` (eg `authored: nil`).
  def questionnaire_response_hash(items, include_display: true, **overrides)
    {
      resourceType: 'QuestionnaireResponse',
      extension: root_extensions,
      identifier: { system: 'http://example.org/questionnaire-responses', value: '1' },
      status: 'in-progress',
      questionnaire: 'http://example.org/Questionnaire/adaptive|1.0.0',
      _questionnaire: include_display ? questionnaire_display_extension : nil,
      subject: { reference: 'Patient/1' },
      authored: '2024-01-01T00:00:00Z',
      author: { reference: 'Practitioner/1' },
      source: { reference: 'Patient/1' },
      item: items
    }.merge(overrides).compact
  end

  # Populates every item-level must support: linkId, text, the ItemSignature extension, answers of
  # every type, the answer extensions, item.item, and item.answer.item.
  def conformant_items(answers: answers_of_every_type)
    [
      { linkId: 'G1', text: 'Group', extension: [signature_extension],
        item: [{ linkId: 'Q1', text: 'Question one', answer: answers }] },
      { linkId: 'Q2', text: 'Parent question',
        answer: [{ valueBoolean: true, extension: answer_extensions,
                   item: [{ linkId: 'Q2.1', text: 'Child question', answer: [{ valueString: 'child' }] }] }] }
    ]
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

  it 'checks every profile must support element plus source and each answer type' do
    strings = described_class::MUST_SUPPORT_METADATA.must_support_strings

    expect(strings).to include('identifier', 'subject', 'source', 'item.linkId', 'item.answer.item', 'item.item',
                               'extension:intendedUse', 'item.answer.extension:origin',
                               'questionnaire.extension:questionnaireDisplay', 'item.answer.valueAttachment')
    expect(strings).to_not include('item.answer.value[x]')
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

  it 'passes when a bare QuestionnaireResponse populates every must support element' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items)))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'extracts the QuestionnaireResponse from a Parameters request body' do
    create_nq_request(parameters_body(questionnaire_response_hash(conformant_items)))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  it 'fails naming the missing element when a root element is never populated' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items, authored: nil)))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Could not find authored in')
  end

  it 'fails naming source when it is never populated, even though the profile does not flag it' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items, source: nil)))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Could not find source in')
  end

  it 'fails naming a profile must support extension that is never populated' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items,
                                                            extension: root_extensions(except: :intended_use))))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('QuestionnaireResponse.extension:intendedUse')
  end

  it 'fails naming the missing extension when questionnaireDisplay is never populated' do
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items, include_display: false)))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('QuestionnaireResponse.questionnaire.extension:questionnaireDisplay')
  end

  it 'fails naming the missing type when one answer choice type is never used' do
    answers = answers_of_every_type.reject { |answer| answer.key?(:valueAttachment) }
    create_nq_request(bare_body(questionnaire_response_hash(conformant_items(answers:))))

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('Could not find item.answer.valueAttachment in')
  end

  it 'reports the number of QuestionnaireResponses actually analyzed, even when items are nested' do
    2.times do
      create_nq_request(bare_body(questionnaire_response_hash(conformant_items, authored: nil)))
    end

    result = run(described_class)

    expect(result.result).to eq('fail')
    expect(result.result_message).to include('in the 2 provided resource(s)')
  end

  it 'accumulates coverage across several requests when no single QuestionnaireResponse has everything' do
    first_item, second_item = conformant_items
    create_nq_request(bare_body(questionnaire_response_hash([first_item], include_display: false, source: nil)))
    create_nq_request(parameters_body(questionnaire_response_hash([second_item], authored: nil, extension: nil)))

    result = run(described_class)

    expect(result.result).to eq('pass'), result.result_message
  end

  describe 'nested items' do
    # Populates every item-level must support except item.text and a string answer, so the outcome
    # hinges on whether the deeply nested text and answer are credited.
    def items_without_text_or_string_answer
      answers = answers_of_every_type.reject { |answer| answer.key?(:valueString) }
      answers[0] = answers[0].merge(extension: answer_extensions)
      [
        { linkId: 'Q1', extension: [signature_extension], answer: answers },
        { linkId: 'G1', item: [{ linkId: 'G1.1', answer: [{ valueBoolean: true }] }] },
        { linkId: 'Q2', answer: [{ valueBoolean: true, item: [{ linkId: 'Q2.1', answer: [{ valueBoolean: true }] }] }] }
      ]
    end

    def deepest_item(text: 'Deep question')
      { linkId: 'D.1.1', text:, answer: [{ valueString: 'deep' }] }.compact
    end

    def run_with_nested(nested_item)
      create_nq_request(bare_body(questionnaire_response_hash(items_without_text_or_string_answer + [nested_item])))
      run(described_class)
    end

    it 'credits item.text and an answer type that appear only three levels deep under item.item' do
      result = run_with_nested({ linkId: 'D', item: [{ linkId: 'D.1', item: [deepest_item] }] })

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'credits item.text and an answer type that appear only three levels deep under item.answer.item' do
      result = run_with_nested(
        { linkId: 'D', answer: [{ valueBoolean: true,
                                  item: [{ linkId: 'D.1', answer: [{ valueBoolean: true, item: [deepest_item] }] }] }] }
      )

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'credits nested items reached through a mix of item.item and item.answer.item' do
      result = run_with_nested(
        { linkId: 'D', item: [{ linkId: 'D.1', answer: [{ valueBoolean: true, item: [deepest_item] }] }] }
      )

      expect(result.result).to eq('pass'), result.result_message
    end

    it 'still fails, counting only the one QuestionnaireResponse, when no item at any depth has text' do
      result = run_with_nested(
        { linkId: 'D', answer: [{ valueBoolean: true, item: [deepest_item(text: nil)] }] }
      )

      expect(result.result).to eq('fail')
      expect(result.result_message).to include('Could not find item.text in the 1 provided resource(s)')
    end
  end
end
