RSpec.describe DaVinciDTRTestKit::DTRQuestionnaireResponseGroup do
  include Rack::Test::Methods

  def app
    Inferno::Web.app
  end

  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_questionnaire_response') }
  let(:suite_id) { :dtr_smart_app }
  let(:questionnaire_response_url) { "/custom/#{suite_id}/fhir/QuestionnaireResponse" }
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

  describe 'Behavior of questionnaire response save test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'dtr_questionnaire_response_save' } }
    let(:results_repo) { Inferno::Repositories::Results.new }
    let(:access_token) { '1234' }

    it 'passes if questionnaire package POST request is received' do
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:questionnaire_response_url).and_return(questionnaire_response_url)
      )

      result = run(runnable, test_session, access_token:)
      expect(result.result).to eq('wait')

      header 'Authorization', "Bearer #{access_token}"
      post(questionnaire_response_url, '')
      expect(last_response.created?).to be(true)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end

  describe 'Behavior of questionnaire response validation test' do
    let(:runnable) do
      group.tests.find do |test|
        test.id.to_s.end_with? 'dtr_questionnaire_response_pre_population'
      end
    end
    let(:request_body) do
      File.read(File.join(__dir__, '..', 'fixtures', 'questionnaire_response_conformant.json'))
    end

    it 'passes if questionnaire response pre-population is conformant' do
      allow_any_instance_of(DaVinciDTRTestKit::DTRQuestionnaireResponseValidation).to(
        receive(:validate_questionnaire_pre_population).and_return(nil)
      )

      repo_create(:request, name: 'questionnaire_response_save', url: questionnaire_response_url,
                            request_body:, test_session_id: test_session.id)

      result = run(runnable, test_session)
      expect(result.result).to eq('pass'), result.result_message
    end

    it 'fails if questionnaire response input parameters are nonconformant' do
      allow_any_instance_of(DaVinciDTRTestKit::DTRQuestionnaireResponseValidation).to(
        receive(:validate_questionnaire_pre_population).and_raise(Inferno::Exceptions::AssertionException)
      )

      repo_create(:request, name: 'questionnaire_response_save', request_body:, test_session_id: test_session.id)

      result = run(runnable, test_session)
      expect(result.result).to eq('fail')
    end
  end
end
