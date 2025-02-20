RSpec.describe DaVinciDTRTestKit::DTRQuestionnaireRenderingGroup do
  include Rack::Test::Methods

  def app
    Inferno::Web.app
  end

  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_resp_rendering') }
  let(:suite_id) { :dtr_smart_app }
  let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass" }
  let(:resume_fail_url) { "/custom/#{suite_id}/resume_fail" }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:test_runs_repo) { Inferno::Repositories::TestRuns.new }

  def run(runnable, test_session, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name) || :text
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  describe 'Behavior of questionnaire rendering attestation test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'dtr_resp_rendering_attest' } }
    let(:results_repo) { Inferno::Repositories::Results.new }

    it 'passes if affirmative attestation is given' do
      # For some reason it seems to completely ignore an allow...receive for resume_pass_url, so do this instead
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:suite_id).and_return(suite_id)
      )

      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, name: 'questionnaire_package', request_body: nil,
                            test_session_id: test_session.id, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])

      result = run(runnable, test_session)
      expect(result.result).to eq('wait')

      token = test_runs_repo.last_test_run(test_session.id).identifier
      get("#{resume_pass_url}?token=#{token}")

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'fails if negative attestation is given' do
      # For some reason it seems to completely ignore an allow...receive for resume_fail_url, so do this instead
      allow_any_instance_of(DaVinciDTRTestKit::URLs).to(
        receive(:suite_id).and_return(suite_id)
      )

      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, name: 'questionnaire_package', request_body: nil,
                            test_session_id: test_session.id, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_PACKAGE_TAG])

      result = run(runnable, test_session)
      expect(result.result).to eq('wait')

      token = test_runs_repo.last_test_run(test_session.id).identifier
      get("#{resume_fail_url}?token=#{token}")

      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end
  end
end
