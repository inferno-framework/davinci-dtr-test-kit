# frozen_string_literal: true

require_relative 'urls'

module DaVinciDTRTestKit
  module MockEHR
    RESOURCE_SERVER_BASE = ENV.fetch('FHIR_REFERENCE_SERVER')
    RESOURCE_SERVER_BEARER_TOKEN = 'SAMPLE_TOKEN'

    RESPONSE_HEADERS = { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }.freeze

    def resource_server_client
      return @resource_server_client if @resource_server_client

      client = FHIR::Client.new(RESOURCE_SERVER_BASE)
      client.set_bearer_token(RESOURCE_SERVER_BEARER_TOKEN)
      @resource_server_client = client
    end

    def metadata_handler(_env)
      cs = resource_server_client.capability_statement
      if cs.present?
        [200, RESPONSE_HEADERS, [cs.to_json]]
      else
        [500, {}, ['Unexpected error occurred while fetching metadata']]
      end
    end

    def get_fhir_resource(request, _test = nil, _test_result = nil)
      resource_type, id = resource_type_and_id_from_url(request.url)
      request.response_headers = RESPONSE_HEADERS

      begin
        fhir_class = FHIR.const_get(resource_type)
      rescue NameError
        resource_type = nil
      end

      if resource_type.present?
        response = if id.present?
                     resource_server_client.read(fhir_class, id)
                   else
                     resource_server_client.search(fhir_class, search: { parameters: request.query_parameters })
                   end
        request.status = response.code
        request.response_body = response.body
      else
        request.status = 400
        request.response_headers = { 'Content-Type': 'application/json' }
        request.response_body = FHIR::OperationOutcome.new(
          issue: FHIR::OperationOutcome::Issue.new(severity: 'warning', code: 'not-supported',
                                                   details: FHIR::CodeableConcept.new(
                                                     text: 'No recognized resource type in URL'
                                                   ))
        ).to_json
      end
    end

    def questionnaire_response_response(request, _test = nil, _test_result = nil)
      request.status = 201
      request.response_headers = RESPONSE_HEADERS
      request.response_body = request.request_body
    end

    # Pull resource type and ID from url
    # e.g. http://example.org/fhir/Patient/123 -> ['Patient', '123']
    # @private
    def resource_type_and_id_from_url(url)
      path = url.split('?').first.split('/fhir/').second
      path.sub!(%r{/$}, '')
      path.split('/')
    end
  end
end
