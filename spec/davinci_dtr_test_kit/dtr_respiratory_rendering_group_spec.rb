RSpec.describe DaVinciDTRTestKit::DTRRespiratoryRenderingGroup, :runnable, :request do
  def app
    Inferno::Web.app
  end

  let(:group) { Inferno::Repositories::TestGroups.new.find('dtr_resp_rendering') }
  let(:suite_id) { :dtr_smart_app }
  let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass" }
  let(:resume_fail_url) { "/custom/#{suite_id}/resume_fail" }
  let(:test_runs_repo) { Inferno::Repositories::TestRuns.new }

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

      result = run(runnable)
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

      result = run(runnable)
      expect(result.result).to eq('wait')

      token = test_runs_repo.last_test_run(test_session.id).identifier
      get("#{resume_fail_url}?token=#{token}")

      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end
  end
end
