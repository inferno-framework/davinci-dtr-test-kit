# frozen_string_literal: true

require_relative '../endpoints/mock_authorization'

module DaVinciDTRTestKit
  module MockEHR
    RESOURCE_SERVER_BASE = ENV.fetch('FHIR_REFERENCE_SERVER')
    RESOURCE_SERVER_BEARER_TOKEN = 'SAMPLE_TOKEN'

    module_function

    def resource_server_client
      client = FHIR::Client.new(RESOURCE_SERVER_BASE)
      client.set_bearer_token(RESOURCE_SERVER_BEARER_TOKEN)
      client
    end

    def metadata(env)
      cs = resource_server_client.capability_statement
      if cs.present?
        # Overwrite the OAuth URIs returned by the reference server to point to the suite endpoints instead
        oauth_uris_url = 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
        base_url = MockAuthorization.env_base_url(env, METADATA_PATH)
        sec_ext = cs.rest.first&.security&.extension&.delete_if { |e| e.url == oauth_uris_url }
        sec_ext&.push(
          FHIR::Extension.new(
            url: oauth_uris_url,
            extension: [
              FHIR::Extension.new(url: 'authorize', valueUri: MockAuthorization.authorization_endpoint(base_url)),
              FHIR::Extension.new(url: 'token', valueUri: MockAuthorization.token_endpoint(base_url))
            ]
          )
        )

        [200, { 'Content-Type' => 'application/fhir+json', 'Access-Control-Allow-Origin' => '*' }, [cs.to_json]]
      else
        [500, { 'Access-Control-Allow-Origin' => '*' }, ['Unexpected error occurred while fetching metadata']]
      end
    end
  end
end
