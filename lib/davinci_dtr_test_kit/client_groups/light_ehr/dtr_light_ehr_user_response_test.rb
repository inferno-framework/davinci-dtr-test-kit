require_relative '../../urls'
require_relative '../../tags'

module DaVinciDTRTestKit
  class DTRLightEHRUserResponseTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_user_response
    title 'Checks for a valid user response at the supported payer endpoint'
    description %(
      This test verifies that a user-provided response is valid
      when a request is made to the supported payer endpoint.
    )

    input :unique_url_id, type: :text

    run do
      load_tagged_requests(SUPPORTED_PAYER_TAG)
      user_response = request.query_parameters['user_response']

      if user_response.blank?
        pass 'No user response provided, skipping validation and using default response.'
      else
        assert valid_response?(user_response), 'User response is invalid.'
        pass 'User response is present and valid.'
      end
    end

    private

    def valid_response?(response)
      return false if response.nil?

      parsed_response = parse_json(response)
      return false if parsed_response.nil?

      return false unless payers_key?(parsed_response)
      return false unless payers_is_array?(parsed_response)
      return false unless parsed_response['payers'].present?

      parsed_response['payers'].all? { |payer| valid_payer?(payer) }
    end

    def parse_json(response)
      JSON.parse(response)
    rescue JSON::ParserError
      nil
    end

    def valid_hash?(response)
      response.is_a?(Hash)
    end

    def payers_key?(response)
      response.key?('payers')
    end

    def payers_is_array?(response)
      response['payers'].is_a?(Array)
    rescue NoMethodError, TypeError
      false
    end

    def valid_payer?(payer)
      payer.is_a?(Hash) && payer.key?('id') && payer.key?('name')
    end
  end
end
