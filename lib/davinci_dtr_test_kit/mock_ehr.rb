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

    def get_fhir_resource(request, _test = nil, test_result = nil)
      resource_type, id = resource_type_and_id_from_url(request.url)
      request.response_headers = RESPONSE_HEADERS

      begin
        fhir_class = FHIR.const_get(resource_type)
      rescue NameError
        resource_type = nil
      end

      if resource_type.blank?
        request.status = 400
        request.response_headers = { 'Content-Type': 'application/json' }
        request.response_body = FHIR::OperationOutcome.new(
          issue: FHIR::OperationOutcome::Issue.new(severity: 'warning', code: 'not-supported',
                                                   details: FHIR::CodeableConcept.new(
                                                     text: 'No recognized resource type in URL'
                                                   ))
        ).to_json
        return
      end

      # Respond with user-inputted resource if there is one that matches the request
      ehr_bundle_input = JSON.parse(test_result.input_json).find { |input| input['name'] == 'ehr_bundle' }&.dig('value')
      ehr_bundle = FHIR.from_contents(ehr_bundle_input) if ehr_bundle_input.present?
      if id.present? && ehr_bundle.present? && ehr_bundle.is_a?(FHIR::Bundle)
        matching_resource = ehr_bundle.entry&.find do |entry|
          entry.resource.is_a?(fhir_class) && entry.resource&.id == id
        end&.resource
        if matching_resource.present?
          request.status = 200
          request.response_headers = { 'Content-Type': 'application/json' }
          request.response_body = matching_resource.to_json
          return
        end
      end

      # Proxy resource request to the reference server
      response = if id.present?
                   resource_server_client.read(fhir_class, id)
                 else
                   resource_server_client.search(fhir_class, search: { parameters: request.query_parameters })
                 end
      request.status = response.code
      request.response_body = response.body
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
