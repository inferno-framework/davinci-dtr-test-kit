require_relative '../../tags'

module DaVinciDTRTestKit
  class LightEHRSupportedPayerEndpoint < Inferno::DSL::SuiteEndpoint
    def name
      'light_ehr_supported_payer_endpoint'
    end

    def test_run_identifier
      request.params[:tester_url_id]
    end

    def tags
      [SUPPORTED_PAYER_TAG]
    end

    def make_response
      if request.headers['Accept'] == 'application/json'
        user_response = parse_user_response

        if user_response.nil?
          skip_response
          response.body = default_response
        elsif valid_response?(user_response)
          response.status = 200
          response.headers['Content-Type'] = 'application/json'
          response.body = user_response.to_json
        else
          response.status = 400
          response.headers['Content-Type'] = 'application/json'
          response.body = { error: 'Invalid response format' }.to_json
        end
      else
        response.status = 406
        response.headers['Content-Type'] = 'application/json'
        response.body = { error: 'Not Acceptable' }.to_json
      end
      update_result
    end

    private

    def parse_user_response
      user_response = request.params[:user_response]

      return nil if user_response.nil? || user_response.empty?

      begin
        JSON.parse(user_response)
      rescue JSON::ParserError
        nil
      end
    end

    def valid_response?(response)
      return false if response.nil?
      return false unless valid_hash?(response)
      return false unless payers_key?(response)
      return false unless payers_is_array?(response)

      response['payers'].all? { |payer| valid_payer?(payer) }
    end

    def valid_hash?(response)
      response.is_a?(Hash)
    end

    def payers_key?(response)
      response.key?('payers')
    end

    def payers_is_array?(response)
      response['payers'].is_a?(Array)
    end

    def valid_payer?(payer)
      payer.is_a?(Hash) && payer.key?('id') && payer.key?('name')
    end

    def skip_response
      response.status = 200
      response.headers['Content-Type'] = 'application/json'
    end

    def default_response
      {
        payers: [
          { id: 'payer1', name: 'Payer One' },
          { id: 'payer2', name: 'Payer Two' }
        ]
      }.to_json
    end

    def update_result
      if response.status == 200
        results_repo.update_result(result.id, 'pass')
      else
        results_repo.update_result(result.id, 'fail')
      end
    end
  end
end
