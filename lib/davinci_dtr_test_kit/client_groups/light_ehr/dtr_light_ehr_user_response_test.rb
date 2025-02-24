require_relative '../../urls'
require_relative '../../tags'

module DaVinciDTRTestKit
  # noinspection RubyJumpError,RubyResolve
  class DTRLightEHRUserResponseTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_user_response
    title 'Checks for a valid user response at the supported payer endpoint'
    description %(
      This test verifies that a user-provided response is valid
      when a request is made to the supported payer endpoint.
    )

    input :unique_url_id, type: :text
    input :user_response, type: :textarea, optional: true

    run do
      if user_response.nil?
        pass 'No user response provided, skipping validation and using default response.'
        return
      end

      load_tagged_requests(SUPPORTED_PAYER_TAG)
      request_record = requests.find { |r| r.tags.include?(SUPPORTED_PAYER_TAG) }

      begin
        parsed_response = JSON.parse(request_record.response_body)
      rescue JSON::ParserError
        assert false, 'User response is not valid JSON.'
      end

      assert valid_response?(parsed_response), 'User response is invalid.'
      pass 'User response is present and valid.'
    end

    private

    def valid_response?(parsed_response)
      return false if parsed_response.nil?

      return false unless parsed_response.is_a?(Hash)
      return false unless parsed_response.key?('payers')
      return false unless parsed_response['payers'].is_a?(Array)
      return false unless parsed_response['payers'].present?

      parsed_response['payers'].all? { |payer| valid_payer?(payer) }
    end

    def valid_payer?(payer)
      payer.is_a?(Hash) && payer.key?('id') && payer.key?('name')
    end
  end
end
