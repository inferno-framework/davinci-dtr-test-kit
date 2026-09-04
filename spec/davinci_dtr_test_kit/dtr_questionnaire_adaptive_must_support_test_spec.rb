RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220QuestionnaireAdaptiveMustSupportTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:tags) { [DaVinciDTRTestKit::CLIENT_QUESTIONNAIRE_MUST_SUPPORT, DaVinciDTRTestKit::CLIENT_NEXT_TAG] }

  def create_tagged_request(response_body, url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$next-question',
                            request_tags: tags)
    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags: request_tags,
      status: 200
    )
  end

  # Satisfies dtr_questionnaire_adapt's must supports (a differential of dtr_base_questionnaire):
  # the questionnaireAdaptive extension and the item.enableWhen element.
  def conformant_adaptive_questionnaire(link_id: 'Adaptive')
    {
      resourceType: 'Questionnaire',
      status: 'active',
      extension: [
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueBoolean: true }
      ],
      item: [
        {
          linkId: link_id,
          type: 'string',
          enableWhen: [{ question: 'Q0', operator: 'exists', answerBoolean: true }]
        }
      ]
    }
  end

  def next_question_output_json(questionnaire_hash)
    {
      resourceType: 'Parameters',
      parameter: [
        { name: 'return', resource: { resourceType: 'QuestionnaireResponse', status: 'in-progress',
                                      contained: [questionnaire_hash] } }
      ]
    }.to_json
  end

  # $questionnaire-package's adaptive-flagged entries conform to the adaptive *search* profile
  # (dtr-questionnaire-adapt-search), not dtr-questionnaire-adapt, so this test only reads
  # $next-question responses -- the actual in-progress adaptive form.
  def questionnaire_package_output_json(questionnaire_hash)
    {
      resourceType: 'Parameters',
      parameter: [
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire_hash }] } }
      ]
    }.to_json
  end

  it 'skips when no requests have been made' do
    result = run(described_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to include('Requests must be made')
  end

  it 'ignores $questionnaire-package responses, even with a conformant adaptive-shaped Questionnaire' do
    create_tagged_request(
      questionnaire_package_output_json(conformant_adaptive_questionnaire),
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package',
      request_tags: [DaVinciDTRTestKit::CLIENT_QUESTIONNAIRE_MUST_SUPPORT]
    )

    result = run(described_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to include('Requests must be made')
  end

  it 'skips when the tagged requests contain no adaptive Questionnaires' do
    create_tagged_request({ resourceType: 'QuestionnaireResponse', status: 'in-progress' }.to_json)

    result = run(described_class)
    expect(result.result).to eq('skip')
    expect(result.result_message).to include('No adaptive Questionnaires found')
  end

  it 'fails and lists the missing elements when the adaptive Questionnaire is missing must support elements' do
    incomplete = {
      resourceType: 'Questionnaire', status: 'active',
      extension: [{ url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
                    valueBoolean: true }]
    }
    create_tagged_request(next_question_output_json(incomplete))

    result = run(described_class)
    expect(result.result).to eq('fail')
    expect(result.result_message).to include('item.enableWhen')
  end

  it 'passes when a fully conformant adaptive Questionnaire is present in a $next-question response' do
    create_tagged_request(next_question_output_json(conformant_adaptive_questionnaire))

    result = run(described_class)
    expect(result.result).to eq('pass'), result.result_message
  end
end
