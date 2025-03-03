# lib/davinci_dtr_test_kit/client_groups/light_ehr/dtr_light_ehr_supported_payers_user_response_test.rb
require_relative '../../urls'
require_relative '../../tags'

module DaVinciDTRTestKit
  # noinspection RubyJumpError,RubyResolve
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
