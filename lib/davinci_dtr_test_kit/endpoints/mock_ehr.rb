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

    def metadata(_env)
      cs = resource_server_client.capability_statement
      if cs.present?
        [200, { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }, [cs.to_json]]
      else
        [500, { 'Access-Control-Allow-Origin' => '*' }, ['Unexpected error occurred while fetching metadata']]
      end
    end
  end
end
