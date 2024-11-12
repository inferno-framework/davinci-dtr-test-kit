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

      questionnaire_response = extract_questionnaire_response(input_parameters)
      return questionnaire_response if questionnaire_response.is_a?(FHIR::OperationOutcome)

      questionnaire_response_param = FHIR::Parameters::Parameter.new(name: 'return', resource: questionnaire_response)

      if questionnaire_last_dinner_order_question_present?(questionnaire_response)
        # change the questionnaire response status to completed and return the parameters
        return handle_last_dinner_order(questionnaire_response)
      end

      next_questionnaire = determine_next_questionnaire(questionnaire_response, test_id)

      return missing_next_questionnaire_outcome(test_id) unless next_questionnaire

      update_questionnaire_response(questionnaire_response, next_questionnaire)

      unless questionnaire_in_questionnaire_response_exist?(questionnaire_response, next_questionnaire)
        issue = "Questionnaire #{questionnaire_response.questionnaire} does not exist"
        outcome_param = build_outcome_param([outcome_issue('warning', 'not-found', issue)])
        questionnaire_response_param.name = 'return'
        return build_parameters([questionnaire_response_param, outcome_param])
      end

      questionnaire_response
    end

    def extract_questionnaire_response(input_parameters)
      if input_parameters.is_a?(FHIR::Parameters)
        questionnaire_response_param = find_questionnaire_response(input_parameters)
        return questionnaire_response_param if questionnaire_response_param.is_a?(FHIR::OperationOutcome)

        questionnaire_response = questionnaire_response_param.resource
        return invalid_next_question_param_resource_outcome unless valid_questionnaire_response?(questionnaire_response)

        questionnaire_response
      elsif input_parameters.is_a?(FHIR::QuestionnaireResponse)
        input_parameters
      else
        operation_outcome('error', 'invalid', 'wrong resource type submitted for $next-question request.')
      end
    end

    def determine_next_questionnaire(questionnaire_response, test_id)
      # Retrieve the selected option from the response and determine the next set of questions
      if questionnaire_dinner_order_selection_present?(questionnaire_response)
        dinner_question_from_selection(questionnaire_response, test_id)
      else
        Fixtures.next_question_for_test(test_id)
      end
    end

    def parse_request_body(request)
      FHIR.from_contents(request.request_body)
    rescue StandardError
      operation_outcome('error', 'invalid', 'No valid input parameters')
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

    def operation_outcome(severity, code, text = nil)
      FHIR::OperationOutcome.new(issue: outcome_issue(severity, code, text))
    end

    def outcome_issue(severity, code, text = nil)
      FHIR::OperationOutcome::Issue.new(severity:, code:).tap do |issue|
        issue.details = FHIR::CodeableConcept.new(text:) if text.present?
      end
    end

    def find_questionnaire_response(input_parameters)
      questionnaire_response_param = input_parameters.try(&:parameter)&.find do |param|
        param.name == 'questionnaire-response'
      end
      return questionnaire_response_param if questionnaire_response_param

      operation_outcome('error', 'business-rule',
                        'Input parameter does not have a `parameter:questionnaire-response` slice.')
    end

    def valid_questionnaire_response?(questionnaire_response)
      questionnaire_response.is_a?(FHIR::QuestionnaireResponse)
    end

    def invalid_next_question_param_resource_outcome
      issue = 'Input `parameter:questionnaire-response.resource` is missing or not a QuestionnaireResponse.'
      operation_outcome('error', 'business-rule', issue)
    end

    def missing_next_questionnaire_outcome(test_id)
      operation_outcome('error', 'business-rule', "No Questionnaire found for Inferno test #{test_id}")
    end

    def handle_last_dinner_order(questionnaire_response)
      update_questionnaire_response(questionnaire_response)
      questionnaire_response
    end

    # Retrieve the selected option from the response and determine the next set of questions
    def dinner_question_from_selection(questionnaire_response, test_id)
      option = retrieve_dinner_order_selection(questionnaire_response)
      unless option
        issue = 'Cannot determine next question to return: Dinner order selection answer missing '
        return operation_outcome('error', 'business-rule', issue)
      end

      Fixtures.next_question_for_test(test_id, option)
    end

    def questionnaire_in_questionnaire_response_exist?(questionnaire_response, next_questionnaire)
      questionnaire_response.questionnaire&.include?(next_questionnaire.id)
    end

    def questionnaire_dinner_order_selection_present?(questionnaire_response)
      # LinkId = 3.1 for the What would you like for dinner? question
      path = "contained.where($this is Questionnaire).item.where(linkId = '3').item.where(linkId = '3.1').exists()"
      result = evaluator.evaluate_fhirpath(questionnaire_response, path, new)
      !!result.first&.dig('element')
    end

    def questionnaire_last_dinner_order_question_present?(questionnaire_response)
      # LinkId = 3.3 for the Any special requests? question
      path = "contained.where($this is Questionnaire).item.where(linkId = '3').item.where(linkId = '3.3').exists()"
      result = evaluator.evaluate_fhirpath(questionnaire_response, path, new)
      !!result.first&.dig('element')
    end

    def retrieve_dinner_order_selection(questionnaire_response)
      # LinkId = 3.1 for the What would you like for dinner? question
      path = "item.where(linkId = '3').item.where(linkId = '3.1').answer.where(value is Coding).value.code"
      result = evaluator.evaluate_fhirpath(questionnaire_response, path, new)
      result.first&.dig('element')&.parameterize&.underscore
    end

    def update_questionnaire_response(questionnaire_response, next_questionnaire = nil)
      if next_questionnaire
        questionnaire_response.contained.reject! { |resource| resource.resourceType == 'Questionnaire' }
        questionnaire_response.contained << next_questionnaire
      else
        questionnaire_response.status = 'completed'
      end
    end

    def find_questionnaire_canonical(questionnaire_package)
      questionnaire_package&.entry&.find { |e| e.resource.is_a?(FHIR::Questionnaire) }&.resource&.url
    end
  end
end
