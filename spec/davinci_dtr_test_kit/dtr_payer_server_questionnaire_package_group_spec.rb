RSpec.describe DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('dtr_payer_server') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }
  let(:server_endpoint) { 'http://example.com/fhir' }
  let(:test) do
    Class.new(DaVinciDTRTestKit::DTRPayerServerQuestionnairePackageGroup) do
      fhir_client { url :server_endpoint }
      input :server_endpoint
    end
  end
    let(:questionnaire_parameters) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_ri.json'))
    end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  it 'passes if payer server returns valid static questionnaire' do
    stub_request(:post, "#{server_endpoint}/Questionnaire/$questionnaire-package/")
      .with(
        body: JSON.parse(questionnaire_parameters)
      )
      .to_return(status: 200, body: {}.to_json)

    result = run(test, questionnaire_parameters:, server_endpoint:)
    expect(result.result).to eq('pass')
  end
end