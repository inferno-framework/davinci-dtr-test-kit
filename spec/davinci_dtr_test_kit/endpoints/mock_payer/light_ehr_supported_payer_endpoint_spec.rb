require_relative '../../../request_helper'
require_relative '../../../../lib/davinci_dtr_test_kit/endpoints/mock_payer/light_ehr_supported_payer_endpoint'

RSpec.describe DaVinciDTRTestKit::Endpoints::MockPayer::LightEHRSupportedPayerEndpoint do
  include Rack::Test::Methods

  def app
    Inferno::Web.app
  end

  let(:suite_id) { :dtr_light_ehr }
  let(:resume_pass_url) { "/custom/#{suite_id}/resume_pass" }
  let(:resume_fail_url) { "/custom/#{suite_id}/resume_fail" }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:test_runs_repo) { Inferno::Repositories::TestRuns.new }
  let(:results_repo) { Inferno::Repositories::Results.new }

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

  describe 'Supported Payers Endpoint' do
    let(:runnable) { Inferno::Repositories::TestGroups.new.find('light_ehr_supported_payer_endpoint') }

    it 'passes when a request is made to the supported payers endpoint' do
      header 'Accept', 'application/json'
      get '/supported-payers'

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to eq('application/json')
      expect(JSON.parse(last_response.body)['payers']).to be_an(Array)

      result = repo_create(:result, test_session_id: test_session.id)
      repo_create(:request, result_id: result.id, name: 'supported_payers', request_body: nil,
                            test_session_id: test_session.id, tags: ['supported_payers'])

      result = run(runnable, test_session)
      expect(result.result).to eq('wait')

      token = test_runs_repo.last_test_run(test_session.id).identifier
      get("#{resume_pass_url}?token=#{token}")

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'returns 406 when Accept header is missing or incorrect' do
      get '/supported-payers'

      expect(last_response.status).to eq(406)
      expect(JSON.parse(last_response.body)['error']).to eq('Not Acceptable')
    end
  end
end
