# frozen_string_literal: true

require_relative '../../urls'
require_relative 'constants'

module DaVinciDTRTestKit
  module MockAuthorization
    AUTHORIZED_PRACTITIONER_ID = 'pra1234' # Must exist on the FHIR_REFERENCE_SERVER (env var)

    class TokenEndpoint < Inferno::DSL::SuiteEndpoint
      def test_run_identifier
        extract_client_id
      end

      def make_response
        client_id = extract_client_id
        access_token = JWT.encode({ inferno_client_id: client_id }, nil, 'none')
        granted_scopes = SUPPORTED_SCOPES & requested_scopes

        response_hash = { access_token:, scope: granted_scopes.join(' '), token_type: 'bearer', expires_in: 3600 }

        if granted_scopes.include?('openid')
          response_hash.merge!(id_token: create_id_token(client_id, fhir_user: granted_scopes.include?('fhirUser')))
        end

        fhir_context_input = find_test_input('smart_fhir_context')
        begin
          fhir_context = JSON.parse(fhir_context_input)
        rescue StandardError
          fhir_context = nil
        end
        response_hash.merge!(fhirContext: fhir_context) if fhir_context

        smart_patient_input = find_test_input("#{input_group_prefix}_smart_patient_id")
        response_hash.merge!(patient: smart_patient_input) if smart_patient_input

        response.body = response_hash.to_json
        response.headers.merge(
          'Cache-Control' => 'no-store',
          'Pragma' => 'no-cache',
          'Access-Control-Allow-Origin' => '*'
        )
        response.status = 200
      end

      private

      def extract_client_id
        # Public client            || confidential client asymmetric          || confidential client symmetric
        request.params[:client_id] || extract_client_id_from_client_assertion || extract_client_id_from_basic_auth
      end

      def extract_client_id_from_client_assertion
        encoded_jwt = request.params[:client_assertion]
        return unless encoded_jwt.present?

        jwt_payload =
          begin
            JWT.decode(encoded_jwt, nil, false)&.first # skip signature verification
          rescue StandardError
            nil
          end

        jwt_payload['iss'] || jwt_payload['sub'] if jwt_payload.present?
      end

      def input_group_prefix
        if test.id.include?('static')
          'static'
        elsif test.id.include?('adaptive')
          'adaptive'
        else
          'resp'
        end
      end

      def find_test_input(input_name)
        JSON.parse(result.input_json)&.find { |input| input['name'] == input_name }&.dig('value')
      end

      def extract_client_id_from_basic_auth
        encoded_credentials = request.headers['authorization']&.delete_prefix('Basic ')
        return unless encoded_credentials.present?

        decoded_credentials = Base64.decode64(encoded_credentials)
        decoded_credentials&.split(':')&.first
      end

      def requested_scopes
        auth_request = requests_repo.tagged_requests(result.test_session_id, [EHR_AUTHORIZE_TAG]).last
        return [] unless auth_request

        auth_params = if auth_request.verb.downcase == 'get'
                        auth_request.query_parameters
                      else
                        URI.decode_www_form(auth_request.request_body)&.to_h
                      end
        scope_str = auth_params&.dig('scope')
        scope_str ? URI.decode_www_form_component(scope_str).split : []
      end

      def create_id_token(client_id, fhir_user: false)
        # No point in mocking an identity provider, just always use known Practitioner as the authorized user
        suite_fhir_base_url = request.url.split(EHR_TOKEN_PATH).first + FHIR_BASE_PATH
        id_token_hash = {
          iss: suite_fhir_base_url,
          sub: AUTHORIZED_PRACTITIONER_ID,
          aud: client_id,
          exp: Time.now.to_i + (24 * 60 * 60), # 24 hrs
          iat: Time.now.to_i
        }
        id_token_hash.merge!(fhirUser: "#{suite_fhir_base_url}/Practitioner/#{AUTHORIZED_PRACTITIONER_ID}") if fhir_user

        JWT.encode(id_token_hash, RSA_PRIVATE_KEY, 'RS256')
      end
    end
  end
end
