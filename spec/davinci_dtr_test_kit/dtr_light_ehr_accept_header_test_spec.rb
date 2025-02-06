RSpec.describe DaVinciDTRTestKit::DTRLightEHRAcceptHeaderTest, :request do
  let(:test) { described_class }
  let(:suite_id) { :dtr_light_ehr }
  let(:unique_url_id) { '12345' }
  let(:supported_payer_url) { "/custom/#{suite_id}/#{unique_url_id}/supported-payers" }
  let(:results_repo) { Inferno::Repositories::Results.new }

  describe 'Accept Header Test' do
    it 'passes when Accept header is correctly set to application/json' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header 'Authorization', unique_url_id
      header 'Accept', 'application/json'
      get supported_payer_url

      expect(last_response.status).to eq(200)

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'returns 406 when Accept header is missing or incorrect' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      header 'Authorization', unique_url_id
      get supported_payer_url

      expect(last_response.status).to eq(406)
      expect(JSON.parse(last_response.body)['error']).to eq('Not Acceptable')

      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end
  end
end
