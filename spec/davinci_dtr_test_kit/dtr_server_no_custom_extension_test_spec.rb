RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::DTRNoCustomExtensionTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:runnable) { described_class }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  let(:questionnaire_resource) do
    {
      resourceType: 'Questionnaire',
      id: 'example-questionnaire',
      status: 'active',
      extension: [
        {
          url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/activeRole',
          valueCode: 'performer'
        }
      ]
    }
  end

  let(:questionnaire_resource_with_custom_extension) do
    {
      resourceType: 'Questionnaire',
      id: 'example-questionnaire-custom',
      status: 'active',
      extension: [
        {
          url: 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/activeRole-custom',
          valueCode: 'performer'
        }
      ]
    }
  end

  def questionnaire_package_parameters(questionnaire:)
    {
      resourceType: 'Parameters',
      parameter: [
        {
          name: 'questionnaire',
          resource: questionnaire
        }
      ]
    }
  end

  def create_questionnaire_package_request(body:, tags:, status: 200)
    repo_create(
      :request,
      result:,
      request_body: body.to_json,
      tags:,
      status:
    )
  end

  it 'skips when no questionnaire-package requests were received' do
    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No requests were made in a previous test as expected')
  end

  it 'skips when successful requests contain no FHIR resource' do
    create_questionnaire_package_request(
      body: {},
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('No FHIR resources were found')
  end

  it 'skips when all questionnaire-package requests were unsuccessful' do
    create_questionnaire_package_request(
      body: questionnaire_package_parameters(questionnaire: questionnaire_resource),
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG],
      status: 500
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message).to include('All service requests were unsuccessful')
  end

  it 'passes when a successful request contains no custom extensions' do
    create_questionnaire_package_request(
      body: questionnaire_package_parameters(questionnaire: questionnaire_resource),
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )
    create_questionnaire_package_request(
      body: questionnaire_package_parameters(questionnaire: questionnaire_resource_with_custom_extension),
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('pass')
  end

  it 'skips if every successful request contains custom extensions' do
    create_questionnaire_package_request(
      body: questionnaire_package_parameters(questionnaire: questionnaire_resource_with_custom_extension),
      tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG]
    )

    test_result = run(runnable)

    expect(test_result.result).to eq('skip')
    expect(test_result.result_message)
      .to include('http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/activeRole-custom')
  end
end
