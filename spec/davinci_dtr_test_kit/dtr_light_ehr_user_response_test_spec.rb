require 'erb'

RSpec.describe DaVinciDTRTestKit::DTRLightEHRUserResponseTest, :request do
  let(:test) { described_class }
  let(:suite_id) { :dtr_light_ehr }
  let(:unique_url_id) { '12345' }
  let(:supported_payer_url) { "/custom/#{suite_id}/#{unique_url_id}/supported-payers" }
  let(:results_repo) { Inferno::Repositories::Results.new }

  describe 'User Response Validation' do
    it 'passes when a valid user response is provided' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      valid_user_response = {
        payers: [
          { id: 'payer1', name: 'Payer One' },
          { id: 'payer2', name: 'Payer Two' }
        ]
      }.to_json

      url_with_params = "#{supported_payer_url}?user_response=#{ERB::Util.url_encode(valid_user_response)}"

      header 'Accept', 'application/json'
      get url_with_params

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to eq('application/json')

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'fails when an invalid user response is provided' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      invalid_user_response = {
        payers: [
          { id: 'payer1' } # Missing 'name' key
        ]
      }.to_json

      url_with_params = "#{supported_payer_url}?user_response=#{ERB::Util.url_encode(invalid_user_response)}"

      header 'Accept', 'application/json'
      get url_with_params

      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)['error']).to eq('Invalid response format')

      result = results_repo.find(result.id)
      expect(result.result).to eq('fail')
    end

    it 'fails when no user response is provided' do
      inputs = { unique_url_id: }
      result = run(test, inputs)
      expect(result.result).to eq('wait')

      url_with_params = supported_payer_url

      header 'Accept', 'application/json'
      get url_with_params

      expect(last_response.status).to eq(200)
      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end
  end
end
