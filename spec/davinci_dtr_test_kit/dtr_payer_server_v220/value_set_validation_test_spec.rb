RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::ValueSetValidationTest do
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  let(:q_with_external) do
    FHIR::Questionnaire.new(
      url: 'urn:example:questionnaire',
      item: [
        {
          item: [
            {
              answerValueSet: 'http://www.example.org/external-answerValueSet|2.2.0'
            }
          ]
        }
      ]
    )
  end

  let(:q_without_external) do
    FHIR::Questionnaire.new(
      url: 'urn:example:questionnaire',
      item: [
        {
          answerValueSet: '#contained-valueset'
        }
      ]
    )
  end

  let(:external_value_set) do
    FHIR::ValueSet.new(
      url: 'http://www.example.org/external-answerValueSet',
      version: '2.2.0'
    )
  end

  def build_bundle(questionnaire, value_sets = [])
    bundle_hash = {
      entry: [
        {
          resource: questionnaire
        }
      ]
    }

    value_sets.each do |vs|
      bundle_hash[:entry] << { resource: vs }
    end

    FHIR::Bundle.new(bundle_hash)
  end

  def response_params(bundle)
    FHIR::Parameters.new(
      parameter: [
        {
          name: 'packagebundle',
          resource: bundle
        }
      ]
    )
  end

  def create_questionnaire_package_request(response_resource, status: 200)
    repo_create(
      :request,
      result_id: result.id,
      name: 'questionnaire_package',
      test_session_id: test_session.id,
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG],
      status:,
      response_body: response_resource.to_json
    )
  end

  it 'skips when no $questionnaire-package requests were made' do
    test_result = run(described_class)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No $questionnaire-package requests were made')
  end

  it 'skips when no successful $questionnaire-package requests were made' do
    create_questionnaire_package_request(FHIR::OperationOutcome.new, status: 500)

    test_result = run(described_class)

    expect(test_result.result).to eq('pass')
    expect(test_result.result_message).to include('No successful $questionnaire-package requests were made')
  end

  it 'fails if Bundle is missing reference to external ValueSet' do
    create_questionnaire_package_request(response_params(build_bundle(q_with_external)))

    test_result = run(described_class)

    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include('Questionnaire-package response Bundles are missing')
  end

  it 'passes when a Bundle includes every externally referenced ValueSet' do
    create_questionnaire_package_request(
      response_params(build_bundle(q_with_external, [external_value_set]))
    )

    test_result = run(described_class)

    expect(test_result.result).to eq('pass'), test_result.result_message
  end

  it 'omits when no Questionnaire contains an external ValueSet reference' do
    create_questionnaire_package_request(response_params(build_bundle(q_without_external)))

    test_result = run(described_class)

    expect(test_result.result).to eq('omit')
    expect(test_result.result_message).to include('No external ValueSet referenced')
  end
end
