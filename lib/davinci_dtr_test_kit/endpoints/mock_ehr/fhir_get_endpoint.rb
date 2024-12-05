require_relative '../mock_authorization'
require_relative '../mock_ehr'

module DaVinciDTRTestKit
  module MockEHR
    class FHIRGetEndpoint < Inferno::DSL::SuiteEndpoint
      include MockEHR

      def test_run_identifier
        MockAuthorization.extract_client_id_from_bearer_token(request)
      end

      def make_response
        fhir_class, id = fhir_class_and_id_from_url(request.url)
        response.format = 'application/fhir+json'
        response.headers['Access-Control-Allow-Origin'] = '*'

        if fhir_class.nil?
          response.status = 400
          response.body = FHIR::OperationOutcome.new(
            issue: FHIR::OperationOutcome::Issue.new(severity: 'warning', code: 'not-supported',
                                                     details: FHIR::CodeableConcept.new(
                                                       text: 'No recognized resource type in URL'
                                                     ))
          ).to_json
          return
        end

        # Respond with user-inputted resource if there is one that matches the request
        ehr_bundle = ehr_input_bundle(test, result)
        if id.present? && ehr_bundle.present?
          matching_resource = find_resource_in_bundle(ehr_bundle, fhir_class, id)
          if matching_resource.present?
            response.status = 200
            response.body = matching_resource.to_json
            return
          end
        end

        # Proxy resource request to the reference server
        proxy_response = if id.present?
                           resource_server_client.read(fhir_class, id)
                         else
                           resource_server_client.search(fhir_class,
                                                         search: { parameters: request.env['rack.request.query_hash'] })
                         end
        response.status = proxy_response.code
        response.body = proxy_response.body
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
end
