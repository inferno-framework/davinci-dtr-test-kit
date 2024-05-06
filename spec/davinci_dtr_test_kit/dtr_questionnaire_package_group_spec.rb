RSpec.describe DaVinciDTRTestKit::DTRQuestionnairePackageGroup do
  include Rack::Test::Methods

  def app
    Inferno::Web.app
  end

  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_questionnaire_package') }
  let(:suite_id) { :dtr_smart_app }
  let(:questionnaire_package_url) { "/custom/#{suite_id}/fhir/Questionnaire/$questionnaire-package" }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }

  def run(runnable, test_session, inputs = {})
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

  describe 'Behavior of questionnaire package request test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'dtr_questionnaire_package_request' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end
    let(:access_token) { '1234' }

    it 'passes if questionnaire package request is received' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_package_url).and_return(questionnaire_package_url)
      )

      result = run(runnable, test_session, access_token:)
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{access_token}"
      post(questionnaire_package_url, request_body)
      expect(last_response.ok?).to be(true)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end

  describe 'Behavior of questionnaire package request validation test' do
    let(:runnable) do
      group.tests.find do |test|
        test.id.to_s.end_with? 'dtr_questionnaire_package_request_validation'
      end
    end
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_package_input_params_conformant.json'))
    end

    it 'passes if questionnaire package input parameters are conformant' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_package_url).and_return(questionnaire_package_url)
      )
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(true)

      repo_create(:request, name: 'questionnaire_package', url: questionnaire_package_url,
                            request_body:, test_session_id: test_session.id)

      result = run(runnable, test_session)
      expect(result.result).to eq('pass'), result.result_message
    end

    it 'fails if questionnaire package input parameters are nonconformant' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_package_url).and_return(questionnaire_package_url)
      )
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(false)

      repo_create(:request, name: 'questionnaire_package', request_body:,
                            test_session_id: test_session.id)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
    end
  end
end
