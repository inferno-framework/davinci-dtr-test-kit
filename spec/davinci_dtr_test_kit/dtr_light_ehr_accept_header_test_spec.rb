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

      # Simulate a request with the correct Accept header
      header 'Authorization', unique_url_id
      header 'Accept', 'application/json'
      get supported_payer_url

      expect(last_response.status).to eq(200)

      # Verify that the test result is updated to pass
      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'returns 406 when Accept header is missing or incorrect' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      # Simulate a request without the Accept header
      header 'Authorization', unique_url_id
      get supported_payer_url

      # Ensure the application logic is set to return 406 for missing/incorrect Accept header
      expect(last_response.status).to eq(406)
      expect(JSON.parse(last_response.body)['error']).to eq('Not Acceptable')

      # Verify that the test result is updated to fail
      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end
  end
end
