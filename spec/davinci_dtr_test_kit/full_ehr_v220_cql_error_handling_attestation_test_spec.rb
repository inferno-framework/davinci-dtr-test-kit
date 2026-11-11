require 'davinci_dtr_test_kit/full_ehr/v2.2.0/interaction/cql_error_handling_attestation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220CQLErrorHandlingAttestationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  before do
    allow_any_instance_of(DaVinciDTRTestKit::URLs).to receive(:suite_id).and_return(suite_id)
  end

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

  def qp_response_json(*questionnaire_hashes)
    {
      resourceType: 'Parameters',
      parameter: questionnaire_hashes.map do |questionnaire_hash|
        { name: 'packagebundle',
          resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire_hash }] } }
      end
    }.to_json
  end

  def questionnaire_hash(url:, version: '1.0.0', title: nil)
    { resourceType: 'Questionnaire', status: 'active', url:, version:, title:,
      item: [{ linkId: '3.3', type: 'string' }] }.compact
  end

  it 'skips when no Questionnaire Package request returned a Questionnaire' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'waits for the attestation, listing the returned Questionnaire and both attestation links' do
    create_qp_request(qp_response_json(questionnaire_hash(url: 'urn:inferno:dtr-test-kit:dinner-order-cql-error',
                                                          title: 'Dinner Order (CQL Error)')))

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message)
      .to include('Dinner Order (CQL Error) (urn:inferno:dtr-test-kit:dinner-order-cql-error|1.0.0)')
    expect(result.result_message).to include('prohibited')
    expect(result.result_message).to include('PHI')
    expect(result.result_message).to include('/resume_pass?token=')
    expect(result.result_message).to include('/resume_fail?token=')
  end

  it 'outputs the attestation urls' do
    create_qp_request(qp_response_json(questionnaire_hash(url: 'urn:inferno:dtr-test-kit:dinner-order-cql-error')))

    run(described_class)

    outputs = Inferno::Repositories::SessionData.new.get_all_from_session(test_session.id).to_h do |data|
      [data.name, data.value]
    end
    expect(outputs['attest_true_url']).to include('/resume_pass?token=')
    expect(outputs['attest_false_url']).to include('/resume_fail?token=')
  end

  describe 'scoping requests to a configured dtr_workflow_tag' do
    let(:scoped_test_class) do
      Class.new(described_class) do
        id :scoped_cql_error_handling_attestation_spec_test
        config options: { dtr_workflow_tag: 'cql_error' }
      end
    end

    before do
      tests_repo = Inferno::Repositories::Tests.new
      tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    end

    it 'ignores requests tagged for a different workflow' do
      create_qp_request(qp_response_json(questionnaire_hash(url: 'urn:inferno:dtr-test-kit:dinner-order-cql-error')),
                        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'static'])

      result = run(scoped_test_class)

      expect(result.result).to eq('skip')
    end

    it 'only considers requests tagged for the configured workflow' do
      create_qp_request(qp_response_json(questionnaire_hash(url: 'urn:inferno:dtr-test-kit:dinner-order-cql-error')),
                        tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'cql_error'])

      result = run(scoped_test_class)

      expect(result.result).to eq('wait')
    end
  end
end
