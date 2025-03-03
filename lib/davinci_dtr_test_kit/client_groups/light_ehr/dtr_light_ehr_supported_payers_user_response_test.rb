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

    def validate_response(parsed_response)
      assert parsed_response.present?, 'User provided response is nil.'

      unless parsed_response.is_a?(Hash)
        add_message('error', 'Response is not a valid JSON object (Hash expected).')
        return
      end

      unless parsed_response['payers'].is_a?(Array)
        add_message('error', 'The "payers" field is not an array.')
        return
      end

      add_message('error', 'Response does not contain the required "payers" key.') unless parsed_response.key?('payers')
      add_message('error', 'The "payers" field is an empty array.') if parsed_response['payers'].empty?

      parsed_response['payers'].each_with_index do |payer, index|
        validate_payer(payer, index)
      end
    end

    def validate_payer(payer, index)
      unless payer.is_a?(Hash)
        add_message('error', "Payer at index #{index} is not a valid JSON object (Hash expected).")
        return
      end

      add_message('error', "Payer at index #{index} does not contain the required 'id' key.") unless payer.key?('id')
      add_message('error', "Payer at index #{index} does not contain the required 'name' key.") unless payer['name']
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

      validate_response(parsed_response)
      assert messages.none? { |msg| msg[:type] == 'error' }, 'User response is invalid.'
      pass 'User response is present and valid.'
    end
  end
end
