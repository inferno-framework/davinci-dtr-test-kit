require_relative '../../urls'

module DaVinciDTRTestKit
  class DTRLightEHRUserResponseTest < Inferno::Test
    include URLs
    id :dtr_light_ehr_user_response
    title 'Checks for a valid user response at the supported payer endpoint'
    description %(
      This test verifies that a user-provided response is present and valid
      when a request is made to the supported payer endpoint.
    )
    input :unique_url_id,
          description: %(
            A unique identifier that will be used to construct the supported payers
            endpoint URL. This allows a permanent configuration for the tester to
            use across Inferno sessions.
          )

    run do
      wait(
        identifier: unique_url_id,
        message: %(
          ### User Response Check

          Inferno will wait for the Light EHR to make a GET request to

          `#{supported_payer_url(unique_url_id)}`

          Inferno will check if a valid user response is provided.

          ### Request Identification

          In order to identify requests for this session, Inferno will look for
          a URL segment with value:

          ```
          #{unique_url_id}
          ```
        )
      )

      user_response = request.params['user_response']

      if user_response.nil?
        raise 'User response is not provided.'
      elsif valid_response?(user_response)
        pass 'User response is present and valid.'
      else
        raise 'User response is invalid.'
      end
    end

    private

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
  end
end
