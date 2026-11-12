require 'davinci_dtr_test_kit/full_ehr/v2.2.0/answer_origin/prepopulation_review_not_required_attestation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220PrepopulationReviewNotRequiredAttestationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  def create_qp_request(tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])
    questionnaire = { resourceType: 'Questionnaire', status: 'active', url: 'http://example.org/Questionnaire/q',
                      item: [{ linkId: 'a', type: 'string' }] }
    response_body = {
      resourceType: 'Parameters',
      parameter: [{ name: 'packagebundle',
                    resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire }] } }]
    }.to_json
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

  it 'waits for the tester to attest when a Questionnaire was returned' do
    create_qp_request

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include('was **not** required to explicitly review')
  end

  it 'skips when no Questionnaire Package request returned a Questionnaire' do
    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'only considers requests tagged for the configured workflow' do
    scoped_test_class = Class.new(described_class) do
      id :scoped_prepopulation_review_attestation_spec_test
      config options: { dtr_workflow_tag: 'answer_origin' }
    end
    tests_repo = Inferno::Repositories::Tests.new
    tests_repo.insert(scoped_test_class) unless tests_repo.exists?(scoped_test_class.id.to_s)
    create_qp_request(tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG, 'other_workflow'])

    result = run(scoped_test_class)

    expect(result.result).to eq('skip')
  end
end
