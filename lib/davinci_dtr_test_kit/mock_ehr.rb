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

    def get_fhir_resource(request, test = nil, test_result = nil)
      fhir_class, id = fhir_class_and_id_from_url(request.url)
      request.response_headers = RESPONSE_HEADERS

      if fhir_class.nil?
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
      ehr_bundle = ehr_input_bundle(test, test_result)
      if id.present? && ehr_bundle.present?
        matching_resource = find_resource_in_bundle(ehr_bundle, fhir_class, id)
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

    def ehr_input_bundle(test, test_result)
      input_name = "#{input_group_prefix(test)}_ehr_bundle"
      ehr_bundle_input = JSON.parse(test_result.input_json).find { |input| input['name'] == input_name }
      ehr_bundle_input_value = ehr_bundle_input_value = ehr_bundle_input['value'] if ehr_bundle_input.present?
      ehr_bundle = FHIR.from_contents(ehr_bundle_input_value) if ehr_bundle_input_value.present?
      ehr_bundle if ehr_bundle.is_a?(FHIR::Bundle)
    rescue StandardError
      nil
    end

    def input_group_prefix(test)
      if test.id.include?('static')
        'static'
      elsif test.id.include?('adaptive')
        'adaptive'
      else
        'resp'
      end
    end

    def find_resource_in_bundle(bundle, fhir_class, id)
      bundle.entry&.find do |entry|
        entry.resource.is_a?(fhir_class) && entry.resource&.id == id
      end&.resource
    end

    # Pull resource type class and ID from url
    # e.g. http://example.org/fhir/Patient/123 -> [FHIR::Patient, '123']
    # @private
    def fhir_class_and_id_from_url(url)
      path = url.split('?').first.split('/fhir/').second
      path.sub!(%r{/$}, '')
      resource_type, id = path.split('/')

      begin
        fhir_class = FHIR.const_get(resource_type)
      rescue NameError
        fhir_class = nil
      end

      [fhir_class, id]
    end
  end
end
