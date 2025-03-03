require_relative '../../urls'
require_relative '../../tags'

module DaVinciDTRTestKit
  class DTRLightEHRSupportedPayersUserResponseTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_sp_user_response
    title %(
      [USER INPUT VERIFICATION] Tester-provided supported payers response is conformant
    )
    description %(
      This test verifies that the user-provided response conforms
      to the requirements for a supported payers response. The test will
      be omitted if the tester does not provide a custom response in the
      **Custom Supported Payers Response** input.
    )

    input :user_response, type: :textarea, optional: true

    def valid_response?(parsed_response)
      if parsed_response.nil?
        assert false, 'Response is nil.'
        return false
      end

      unless parsed_response.is_a?(Hash)
        assert false, 'Response is not a valid JSON object (Hash expected).'
        return false
      end

      unless parsed_response.key?('payers')
        assert false, 'Response does not contain the required "payers" key.'
        return false
      end

      unless parsed_response['payers'].is_a?(Array)
        assert false, 'The "payers" key does not contain an array.'
        return false
      end

      if parsed_response['payers'].empty?
        assert false, 'The "payers" array is empty.'
        return false
      end

      parsed_response['payers'].each_with_index do |payer, index|
        valid_payer?(payer, index)
      end
    end

    def valid_payer?(payer, index)
      unless payer.is_a?(Hash)
        assert false, "Payer at index #{index} is not a valid JSON object (Hash expected)."
        return false
      end

      unless payer.key?('id')
        assert false, "Payer at index #{index} does not contain the required 'id' key."
        return false
      end

      unless payer.key?('name')
        assert false, "Payer at index #{index} does not contain the required 'name' key."
        return false
      end

      true
    end

    run do
      omit_if user_response.nil?, 'No user response provided, default response returned.'

      load_tagged_requests(SUPPORTED_PAYER_TAG)
      request_record = requests.first

      assert request_record.present?, 'No requests made to the supported payers endpoint.'

      begin
        parsed_response = JSON.parse(request_record.response_body)
      rescue JSON::ParserError
        assert false, 'User response is not valid JSON.'
      end

      assert valid_response?(parsed_response), 'User response is invalid.'
      pass 'User response is present and valid.'
    end
  end
end
