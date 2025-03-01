require_relative '../../lib/davinci_dtr_test_kit/tags'

RSpec.describe DaVinciDTRTestKit::DTRLightEHRSupportedPayersAcceptHeaderTest, :request do
  let(:test) { described_class }
  let(:suite_id) { :dtr_light_ehr }
  let(:unique_url_id) { '12345' }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }
  let(:supported_payer_url) { "/custom/#{suite_id}/#{unique_url_id}/supported-payers" }
  let(:results_repo) { Inferno::Repositories::Results.new }

  def create_supported_payers_request(accept_header_value)
    headers ||= [
      {
        type: 'request',
        name: 'Accept',
        value: accept_header_value
      }
    ]
    repo_create(
      :request,
      direction: 'incoming',
      url: supported_payer_url,
      test_session_id: test_session.id,
      result:,
      tags: [DaVinciDTRTestKit::SUPPORTED_PAYER_TAG],
      status: 200,
      headers:
    )
  end

  describe 'Accept Header Test' do
    it 'passes when Accept header is correctly set to application/json' do
      create_supported_payers_request('application/json')
      result = run(test)
      expect(result.result).to eq('pass')
    end

    it 'fails when Accept header is not set to application/json' do
      create_supported_payers_request('/')
      result = run(test)
      expect(result.result).to eq('fail')
    end
  end
end
