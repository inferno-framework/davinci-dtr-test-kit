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

    def client_questionnaire_next_response(request, _test = nil, test_result = nil)
      request.status = 200
      request.response_headers = RESPONSE_HEADERS
      request.response_body = build_questionnaire_next_response(request, test_result.test_id).to_json
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
      input_parameters = parse_request_body(request)
      return input_parameters if input_parameters.is_a?(FHIR::OperationOutcome)

      questionnaire_package = Fixtures.questionnaire_package_for_test(test_id)
      unless questionnaire_package
        return operation_outcome('error', 'business-rule', "No Questionnaire found for Inferno test #{test_id}")
      end

      questionnaire_canonical = find_questionnaire_canonical(questionnaire_package)

      other_questionnaire_params = input_parameters.parameter.filter do |param|
        param.name == 'questionnaire' && param.valueCanonical != questionnaire_canonical
      end

      return questionnaire_package unless other_questionnaire_params.any?

      package_bundle_param = FHIR::Parameters::Parameter.new(name: 'PackageBundle', resource: questionnaire_package)
      issues = other_questionnaire_params.map do |param|
        outcome_issue('warning', 'not-found', "Questionnaire #{param.valueCanonical} does not exist")
      end
      outcome_param = build_outcome_param(issues)

      build_parameters([package_bundle_param, outcome_param])
    end

    def build_questionnaire_next_response(request, test_id)
      input_parameters = parse_request_body(request)
      return input_parameters if input_parameters.is_a?(FHIR::OperationOutcome)

      next_questionnaire = Fixtures.next_question_for_test(test_id)
      unless next_questionnaire
        return operation_outcome('error', 'business-rule',
                                 "No additional Questionnaire found for Inferno test #{test_id}")
      end

      questionnaire_response_param = find_questionnaire_response(input_parameters)
      return questionnaire_response_param if questionnaire_response_param.is_a?(FHIR::OperationOutcome)

      questionnaire_response = questionnaire_response_param.resource
      unless valid_questionnaire_response?(questionnaire_response)
        issue = 'Input `parameter:questionnaire-response.resource` is missing or not a QuestionnaireResponse.'
        return operation_outcome('error', 'business-rule', issue)
      end

      unless questionnaire_in_questionnaire_response_exist?(questionnaire_response, next_questionnaire)
        issue = "Questionnaire #{questionnaire_response.questionnaire} does not exist"
        outcome_param = build_outcome_param([outcome_issue('warning', 'not-found', issue)])
        return build_parameters([questionnaire_response_param, outcome_param])
      end

      update_questionnaire_response(questionnaire_response, next_questionnaire)
      build_parameters([questionnaire_response_param])
    end

    def parse_request_body(request)
      FHIR.from_contents(request.request_body)
    rescue StandardError
      operation_outcome('error', 'invalid', 'No valid input parameters')
    end

    def find_questionnaire_response(input_parameters)
      questionnaire_response_param = input_parameters.parameter.find { |param| param.name == 'questionnaire-response' }
      return questionnaire_response_param if questionnaire_response_param

      operation_outcome('error', 'business-rule',
                        'Input parameter does not have a `parameter:questionnaire-response` slice.')
    end

    def valid_questionnaire_response?(questionnaire_response)
      questionnaire_response.is_a?(FHIR::QuestionnaireResponse)
    end

    def questionnaire_in_questionnaire_response_exist?(questionnaire_response, next_questionnaire)
      questionnaire_response.questionnaire == "##{next_questionnaire.id}"
    end

    def build_parameters(parameters)
      FHIR::Parameters.new(parameter: parameters)
    end

    def build_outcome_param(issues)
      FHIR::Parameters::Parameter.new(
        name: 'Outcome',
        resource: FHIR::OperationOutcome.new(issue: issues)
      )
    end

    def update_questionnaire_response(questionnaire_response, next_questionnaire)
      questionnaire_response.contained.reject! { |resource| resource.resourceType == 'Questionnaire' }
      questionnaire_response.contained << next_questionnaire
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
