RSpec.describe DaVinciDTRTestKit::DTRLightEHRSupportedPayerEndpointTest, :request do
  let(:test) { described_class }
  let(:suite_id) { :dtr_light_ehr }
  let(:unique_url_id) { '12345' }
  let(:supported_payer_url) { "/custom/#{suite_id}/#{unique_url_id}/supported-payers" }
  let(:results_repo) { Inferno::Repositories::Results.new }

  describe 'Supported Payers Endpoint' do
    it 'passes when a request is made to the supported payers endpoint' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header 'Accept', 'application/json'
      get supported_payer_url

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to eq('application/json')
      expect(JSON.parse(last_response.body)['payers']).to be_an(Array)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end
end
