require 'erb'
require_relative '../../lib/davinci_dtr_test_kit/tags'

RSpec.describe DaVinciDTRTestKit::DTRLightEHRSupportedPayersUserResponseTest, :request do
  let(:test) { described_class }
  let(:suite_id) { :dtr_light_ehr }
  let(:unique_url_id) { '12345' }
  let(:supported_payer_url) { "/custom/#{suite_id}/#{unique_url_id}/supported-payers" }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:result) { repo_create(:result, test_session_id: test_session.id) }

  def create_supported_payers_request(user_response = nil)
    headers = [
      {
        type: 'request',
        name: 'Accept',
        value: 'application/json'
      }
    ]
    url = supported_payer_url

    repo_create(
      :request,
      direction: 'incoming',
      url:,
      test_session_id: test_session.id,
      result:,
      tags: [DaVinciDTRTestKit::SUPPORTED_PAYER_TAG],
      status: 200,
      headers:,
      request_body: nil,
      response_body: user_response.presence&.to_json || {}.to_json
    )
  end

  describe 'User Response Validation' do
    it 'passes when a valid user response is provided' do
      valid_user_response = {
        payers: [
          { id: 'payerA', name: 'Payer A' },
          { id: 'payerB', name: 'Payer B' }
        ]
      }

      create_supported_payers_request(valid_user_response)
      result = run(test, { user_response: valid_user_response.to_json })
      expect(result.result).to eq('pass')
    end

    it 'fails when response is not a valid JSON object' do
      invalid_user_response = '[]'

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response })
      expect(result.result).to eq('fail')
    end

    it 'fails when response does not contain the required "payers" key' do
      invalid_user_response = {
        not_payers: []
      }

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response.to_json })
      expect(result.result).to eq('fail')
    end

    it 'fails when "payers" key does not contain an array' do
      invalid_user_response = {
        payers: 'not_an_array'
      }

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response.to_json })
      expect(result.result).to eq('fail')
    end

    it 'fails when the "payers" array is empty' do
      invalid_user_response = {
        payers: []
      }

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response.to_json })
      expect(result.result).to eq('fail')
    end

    it 'fails when a payer is not a valid JSON object' do
      invalid_user_response = {
        payers: ['not_a_hash']
      }

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response.to_json })
      expect(result.result).to eq('fail')
    end

    it 'fails when a payer does not contain the required "id" key' do
      invalid_user_response = {
        payers: [
          { name: 'Payer A' }
        ]
      }

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response.to_json })
      expect(result.result).to eq('fail')
    end

    it 'fails when a payer does not contain the required "name" key' do
      invalid_user_response = {
        payers: [
          { id: 'payerA' }
        ]
      }

      create_supported_payers_request(invalid_user_response)
      result = run(test, { user_response: invalid_user_response.to_json })
      expect(result.result).to eq('fail')
    end

    it 'omits when no user response is provided' do
      create_supported_payers_request
      result = run(test)
      expect(result.result).to eq('omit')
    end
  end
end
