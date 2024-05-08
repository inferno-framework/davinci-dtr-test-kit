require_relative 'fixtures'

module DaVinciDTRTestKit
  module MockPayer
    include Fixtures

    RESPONSE_HEADERS = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }.freeze

    def token_response(request, _test = nil, _test_result = nil)
      # Placeholder for a more complete mock token endpoint
      request.response_body = { access_token: SecureRandom.hex, token_type: 'bearer', expires_in: 300 }.to_json
      request.status = 200
    end

    def questionnaire_package_response(request, _test = nil, test_result = nil)
      request.status = 200
      request.response_headers = RESPONSE_HEADERS
      request.response_body = questionnaire_package.to_json
    end

    def questionnaire_response_response(request, _test = nil, _test_result = nil)
      request.status = 201
      request.response_headers = RESPONSE_HEADERS
      request.response_body = request.request_body
    end

    def payer_adaptive_questionnaire_response(request, _test = nil, test_result = nil)
      endpoint_input = JSON.parse(test_result.input_json).find { |input| input['name'] == 'adaptive_endpoint' }
      url_input = JSON.parse(test_result.input_json).find { |input| input['name'] == 'url' }
      client = FHIR::Client.new(url_input['value'])
      client.default_json
      endpoint = endpoint_input['value'].nil? ? '/Questionnaire/$questionnaire-package' : endpoint_input['value']
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

    def extract_client_id(request)
      URI.decode_www_form(request.request_body).to_h['client_id']
    end

    # Header expected to be a bearer token of the form "Bearer: <token>"
    def extract_bearer_token(request)
      request.request_header('Authorization')&.value&.split&.last
    end

    def extract_token_from_query_params(request)
      request.query_parameters['token']
    end

    def test_resumes?(_test)
      false
    end

    def build_package_questionnaire_response(request, test_id)
      test_questionnaire_canonical = find_questionnaire_canonical_for_test_id(test_id)
      test_questionnaire_loaded = false

      bundles = []
      issues = []

      # first try the parameters - load the questionnaire specified by the questionnaire parameter
      input_parameters = FHIR.from_contents(request.request_body)
      input_parameters.parameter.each do |one_parameter|
        next unless one_parameter.name == 'questionnaire'
        next unless one_parameter.valueCanonical

        # don't load test questionnaire if it is also specified explicitly
        test_questionnaire_loaded = true if one_parameter.valueCanonical == test_questionnaire_canonical

        add_questionnaire_canonical_to_response(one_parameter.valueCanonical, bundles, issues)
      end

      unless test_questionnaire_loaded
        if test_questionnaire_canonical
          add_questionnaire_canonical_to_response(test_questionnaire_canonical, bundles, issues)

        elsif bundles.empty?
          # no questionnaire for this test ...
          operation_outcome_issue = FHIR::OperationOutcome::Issue.new
          operation_outcome_issue.severity = 'error'
          operation_outcome_issue.code = 'business-rule'
          details = FHIR::CodeableConcept.new
          details.text = "no questionnaire found for test #{test_id}"
          operation_outcome_issue.details = details
          issues << operation_outcome_issue
        end
      end

      build_package_questionnaire_response_from_lists(bundles, issues)
    end

    def add_questionnaire_canonical_to_response(questionnaire_canonical, bundles, issues)
      questionnaire_bundle = get_questionnaire_packcage_for_canonical(questionnaire_canonical)

      if questionnaire_bundle
        bundles << questionnaire_bundle
      else
        operation_outcome_issue = FHIR::OperationOutcome::Issue.new
        operation_outcome_issue.severity = 'warning'
        operation_outcome_issue.code = 'value'
        details = FHIR::CodeableConcept.new
        details.text = "Questionnaire Canonical #{questionnaire_canonical} does not exist"
        operation_outcome_issue.details = details
        issues << operation_outcome_issue
      end
    end

    def build_package_questionnaire_response_from_lists(bundles, issues)
      response = FHIR::Parameters.new
      bundles.each do |one_bundle|
        return_param = FHIR::Parameters::Parameter.new
        return_param.name = 'return'
        return_param.resource = one_bundle
        response.parameter << return_param
      end

      unless issues.empty?
        outcome = FHIR::OperationOutcome.new
        outcome.issue = issues
        outcome_param = FHIR::Parameters::Parameter.new
        outcome_param.name = 'outcome'
        outcome_param.resource = outcome
        response.parameter << outcome_param
      end

      response
    end
  end
end
