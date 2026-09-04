require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/ui_display_and_interaction_attestation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220UIDisplayAndInteractionAttestationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  def create_qp_request(response_body, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package',
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags:,
      status: 200
    )
  end

  def adaptive_questionnaire_hash(url:, title: nil, name: nil, link_id: 'Adaptive')
    {
      resourceType: 'Questionnaire',
      status: 'active',
      url:,
      title:,
      name:,
      extension: [
        { url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive',
          valueBoolean: true }
      ],
      item: [{ linkId: link_id, type: 'string' }]
    }.compact
  end

  def standard_questionnaire_hash(url:, title: nil, name: nil, link_id: 'Standard')
    {
      resourceType: 'Questionnaire',
      status: 'active',
      url:,
      title:,
      name:,
      item: [{ linkId: link_id, type: 'string' }]
    }.compact
  end

  def qp_response_json(*questionnaire_hashes)
    {
      resourceType: 'Parameters',
      parameter: questionnaire_hashes.map do |questionnaire_hash|
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire_hash }] } }
      end
    }.to_json
  end

  it 'skips when no Questionnaire Package request returned a Questionnaire' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'skips when the only Questionnaire Package response is not valid JSON' do
    create_qp_request('not json')

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'waits, listing a returned adaptive Questionnaire' do
    adaptive = adaptive_questionnaire_hash(url: 'http://example.org/Questionnaire/adaptive1', title: 'Adaptive One')
    create_qp_request(qp_response_json(adaptive))

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include(
      'Adaptive One (http://example.org/Questionnaire/adaptive1)'
    )
  end

  it 'waits, listing a returned standard Questionnaire the same way as an adaptive one' do
    standard = standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std1', title: 'Standard One')
    create_qp_request(qp_response_json(standard))

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include('Standard One (http://example.org/Questionnaire/std1)')
    expect(result.result_message).to_not include('Standard Questionnaire - confirm completed')
  end

  it 'falls back to name when title is absent, and to the bare canonical url when both are absent' do
    named = standard_questionnaire_hash(url: 'http://example.org/Questionnaire/named', name: 'NamedQuestionnaire')
    bare = standard_questionnaire_hash(url: 'http://example.org/Questionnaire/bare')
    create_qp_request(qp_response_json(named, bare))

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include('NamedQuestionnaire (http://example.org/Questionnaire/named)')
    expect(result.result_message).to include("- http://example.org/Questionnaire/bare\n")
  end

  it 'lists each unique returned Questionnaire only once even if returned by multiple requests' do
    standard = standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std1', title: 'Standard One')
    create_qp_request(qp_response_json(standard))
    create_qp_request(qp_response_json(standard))

    result = run(described_class)

    expect(result.result).to eq('wait')
    occurrences = result.result_message.scan('Standard One').length
    expect(occurrences).to eq(1)
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_ui_display_and_interaction_spec_test
        config options: { dtr_workflow_tag: 'additional_must_support' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    end

    it 'ignores requests tagged for a different workflow' do
      standard = standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std1')
      create_qp_request(
        qp_response_json(standard),
        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'some_other_workflow']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
    end

    it 'only considers requests tagged for the configured workflow' do
      standard = standard_questionnaire_hash(url: 'http://example.org/Questionnaire/std1')
      create_qp_request(
        qp_response_json(standard),
        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'additional_must_support']
      )

      result = run(scoped_test_class)

      expect(result.result).to eq('wait')
    end
  end
end
