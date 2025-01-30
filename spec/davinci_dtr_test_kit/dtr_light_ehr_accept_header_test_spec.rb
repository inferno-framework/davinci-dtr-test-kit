RSpec.describe DaVinciDTRTestKit::DTRLightEHRAcceptHeaderTest, :request do
  let(:suite_id) { :dtr_light_ehr }
  let(:unique_url_id) { '12345' }
  let(:supported_payer_url) { "/custom/#{suite_id}/#{unique_url_id}/supported-payers" }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:test_runs_repo) { Inferno::Repositories::TestRuns.new }
  let(:results_repo) { Inferno::Repositories::Results.new }

  describe 'Accept Header Test' do
    let(:runnable) { Inferno::Repositories::TestGroups.new.find('dtr_light_ehr_accept_header') }

    it 'returns 406 when Accept header is missing or incorrect' do
      result = run(runnable)
      expect(result.result).to eq('wait')

      get supported_payer_url

      expect(last_response.status).to eq(406)
      expect(JSON.parse(last_response.body)['error']).to eq('Not Acceptable')
    end
  end
end
