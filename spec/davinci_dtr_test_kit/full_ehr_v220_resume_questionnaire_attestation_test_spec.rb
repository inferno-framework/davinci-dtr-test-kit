require 'davinci_dtr_test_kit/full_ehr/v2.2.0/resume/resume_questionnaire_attestation_test'

RSpec.describe DaVinciDTRTestKit::DTRFullEHRV220ResumeQuestionnaireAttestationTest do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_full_ehr_v220' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  def create_qp_request(response_body, status: 200)
    repo_create(
      :request,
      direction: 'incoming',
      url: '/custom/dtr_full_ehr_v220/fhir/Questionnaire/$questionnaire-package',
      test_session_id: test_session.id,
      result:,
      response_body:,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG],
      status:
    )
  end

  def package_response_json
    questionnaire = { resourceType: 'Questionnaire', status: 'active', title: 'Dinner Order',
                      url: 'urn:inferno:dtr-test-kit:dinner-order-static', item: [{ linkId: '1', type: 'string' }] }
    { resourceType: 'Parameters',
      parameter: [{ name: 'packagebundle',
                    resource: { resourceType: 'Bundle', type: 'collection', entry: [{ resource: questionnaire }] } }] }
      .to_json
  end

  def unchanged_response_json
    { resourceType: 'Parameters',
      parameter: [{ name: 'outcome',
                    resource: { resourceType: 'OperationOutcome',
                                issue: [{ severity: 'information', code: 'informational' }] } }] }.to_json
  end

  it 'skips when no Questionnaire Package request returned a Questionnaire' do
    create_qp_request(unchanged_response_json)

    result = run(described_class)

    expect(result.result).to eq('skip')
    expect(result.result_message).to eq('No Questionnaire Package requests returned a Questionnaire.')
  end

  it 'waits for the attestation, listing the returned Questionnaire once' do
    create_qp_request(package_response_json)
    create_qp_request(unchanged_response_json)

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message).to include('Saved the QuestionnaireResponse with status `in-progress`')
    expect(result.result_message).to include('Relaunched DTR from the saved QuestionnaireResponse')
    expect(result.result_message.scan('Dinner Order (urn:inferno:dtr-test-kit:dinner-order-static)').size).to eq(1)
  end

  it 'ignores requests with an empty response body, such as an expired-token 401' do
    create_qp_request('', status: 401)
    create_qp_request(package_response_json)

    result = run(described_class)

    expect(result.result).to eq('wait')
    expect(result.result_message.scan('Dinner Order (urn:inferno:dtr-test-kit:dinner-order-static)').size).to eq(1)
  end
end
