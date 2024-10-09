# frozen_string_literal: true

require_relative 'fixtures'

module DaVinciDTRTestKit
  module MockPayer
    RESPONSE_HEADERS = { 'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*' }.freeze

    def questionnaire_package_response(request, _test = nil, test_result = nil)
      request.status = 200
      request.response_headers = RESPONSE_HEADERS
      request.response_body = build_questionnaire_package_response(request, test_result.test_id).to_json
    end

    def payer_questionnaire_response(request, _test = nil, test_result = nil)
      endpoint_input = JSON.parse(test_result.input_json).find { |input| input['name'] == 'custom_endpoint' }
      url_input = JSON.parse(test_result.input_json).find { |input| input['name'] == 'url' }
      client = FHIR::Client.new(url_input['value'])
      client.default_json
      endpoint = endpoint_input.to_h['value'].nil? ? '/Questionnaire/$questionnaire-package' : endpoint_input['value']
      payer_response = client.send(:post, endpoint, JSON.parse(request.request_body),
                                   { 'Content-Type' => 'application/json' })

      request.status = 200
      request.response_headers = RESPONSE_HEADERS
      request.response_body = payer_response.response[:body].to_s
    end

    def questionnaire_next_response(request, _test = nil, test_result = nil)
      url_endpoint = JSON.parse(test_result.input_json).find { |input| input['name'] == 'url' }
      client = FHIR::Client.new(url_endpoint['value'])
      client.default_json
      payer_response = client.send(:post, '/Questionnaire/$next-question', JSON.parse(request.request_body),
                                   { 'Content-Type' => 'application/json' })

      request.status = 200
      request.response_headers = RESPONSE_HEADERS

      request.response_body = payer_response.response[:body]
    end

    def test_resumes?(test)
      !test.config.options[:accepts_multiple_requests]
    end

    private

    def build_questionnaire_package_response(request, test_id)
      begin
        input_parameters = FHIR.from_contents(request.request_body)
      rescue StandardError
        return operation_outcome('error', 'invalid', 'No valid input parameters')
      end

      questionnaire_package = Fixtures.questionnaire_package_for_test(test_id)
      unless questionnaire_package
        return operation_outcome('error', 'business-rule', "No Questionnaire found for Inferno test #{test_id}")
      end

      questionnaire_canonical = find_questionnaire_canonical(questionnaire_package)

      other_questionnaire_params = input_parameters.parameter.filter do |param|
        param.name == 'questionnaire' && param.valueCanonical != questionnaire_canonical
      end

      return questionnaire_package unless other_questionnaire_params.any?

      FHIR::Parameters.new(
        parameter: [
          FHIR::Parameters::Parameter.new(
            name: 'PackageBundle',
            resource: questionnaire_package
          ),
          FHIR::Parameters::Parameter.new(
            name: 'Outcome',
            resource: FHIR::OperationOutcome.new(
              issue: other_questionnaire_params.map do |param|
                outcome_issue('warning', 'not-found', "Questionnaire #{param.valueCanonical} does not exist")
              end
            )
          )
        ]
      )
    end

    def find_questionnaire_canonical(questionnaire_package)
      questionnaire_package&.entry&.find { |e| e.resource.is_a?(FHIR::Questionnaire) }&.resource&.url
    end

    def operation_outcome(severity, code, text = nil)
      FHIR::OperationOutcome.new(issue: outcome_issue(severity, code, text))
    end

    def outcome_issue(severity, code, text = nil)
      FHIR::OperationOutcome::Issue.new(severity:, code:).tap do |issue|
        issue.details = FHIR::CodeableConcept.new(text:) if text.present?
      end
    end
  end
end
