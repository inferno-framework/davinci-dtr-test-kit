require_relative '../mock_authorization'
require_relative '../mock_payer'
require_relative '../../fixtures'

module DaVinciDTRTestKit
  module MockPayer
    class NextQuestionEndpoint < Inferno::DSL::SuiteEndpoint
      include MockPayer

      def test_run_identifier
        MockAuthorization.extract_client_id_from_bearer_token(request)
      end

      def tags
        [test.config.options[:next_tag]]
      end

      def make_response
        response.status = 200
        response.format = 'application/fhir+json'
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.body = build_questionnaire_next_response.to_json
      end

      def custom_next_question_requests
        requests_repo.tagged_requests(test_run.test_session_id, ["custom_#{DaVinciDTRTestKit::CLIENT_NEXT_TAG}"])
      end

      def custom_questionnaires
        return @custom_questionnaires unless @custom_questionnaires.nil?

        questionnaires = JSON.parse(result.input_json)
          .find { |input| input['name'].include?('custom_next_question_questionnaires') }
          &.dig('value')
        return unless questionnaires

        @custom_questionnaires = [JSON.parse(questionnaires)].flatten.compact
      end

      def next_custom_questionnaire
        custom_questionnaires[custom_next_question_requests.length]
      end

      def complete_questionnaire?
        custom_questionnaires && next_custom_questionnaire.blank?
      end

      def update_result
        results_repo.update_result(result.id, 'pass') unless test.config.options[:accepts_multiple_requests]
      end

      private

      def evaluator
        @evaluator ||= Inferno::DSL::FhirpathEvaluation::Evaluator.new
      end

      def build_questionnaire_next_response
        input_parameters = parse_fhir_object(request.body.string)
        return input_parameters if input_parameters.is_a?(FHIR::OperationOutcome)

        questionnaire_response = extract_questionnaire_response(input_parameters)
        return questionnaire_response if questionnaire_response.is_a?(FHIR::OperationOutcome)

        questionnaire_response_param = FHIR::Parameters::Parameter.new(name: 'return', resource: questionnaire_response)

        if complete_questionnaire? || questionnaire_last_dinner_order_question_present?(questionnaire_response)
          # change the questionnaire response status to completed and return the parameters
          return complete_questionnaire(questionnaire_response)
        end

        next_questionnaire = determine_next_questionnaire(questionnaire_response, test.id)

        return missing_next_questionnaire_outcome(test.id) unless next_questionnaire

        update_questionnaire_response(questionnaire_response, next_questionnaire)

        unless questionnaire_in_questionnaire_response_exist?(questionnaire_response, next_questionnaire)
          issue = "Questionnaire #{questionnaire_response.questionnaire} does not exist"
          outcome_param = build_outcome_param([outcome_issue('warning', 'not-found', issue)])
          questionnaire_response_param.name = 'return'
          return FHIR::Parameters.new(parameter: [questionnaire_response_param, outcome_param])
        end

        questionnaire_response
      end

      def extract_questionnaire_response(input_parameters)
        if input_parameters.is_a?(FHIR::Parameters)
          questionnaire_response_param = find_questionnaire_response(input_parameters)
          return questionnaire_response_param if questionnaire_response_param.is_a?(FHIR::OperationOutcome)

          questionnaire_response = questionnaire_response_param.resource
          unless valid_questionnaire_response?(questionnaire_response)
            return invalid_next_question_param_resource_outcome
          end

          questionnaire_response
        elsif input_parameters.is_a?(FHIR::QuestionnaireResponse)
          input_parameters
        else
          operation_outcome('error', 'invalid', 'wrong resource type submitted for $next-question request.')
        end
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

      def update_questionnaire_response(questionnaire_response, next_questionnaire = nil)
        if next_questionnaire
          questionnaire_response.contained.reject! { |resource| resource.resourceType == 'Questionnaire' }
          questionnaire_response.contained << next_questionnaire
        else
          questionnaire_response.status = 'completed'
        end
      end

      def determine_next_questionnaire(questionnaire_response, test_id)
        if custom_questionnaires
          FHIR.from_contents(next_custom_questionnaire.to_json)
        # Retrieve the selected option from the response and determine the next set of questions
        elsif questionnaire_dinner_order_selection_present?(questionnaire_response)
          dinner_question_from_selection(questionnaire_response, test_id)
        else
          Fixtures.next_question_for_test(test_id)
        end
      end

      def complete_questionnaire(questionnaire_response)
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
        eval_result = evaluate_fhirpath(questionnaire_response, path)
        !!eval_result.first&.dig('element')
      end

      def questionnaire_last_dinner_order_question_present?(questionnaire_response)
        # LinkId = 3.3 for the Any special requests? question
        path = "contained.where($this is Questionnaire).item.where(linkId = '3').item.where(linkId = '3.3').exists()"
        eval_result = evaluate_fhirpath(questionnaire_response, path)
        !!eval_result.first&.dig('element')
      end

      def retrieve_dinner_order_selection(questionnaire_response)
        # LinkId = 3.1 for the What would you like for dinner? question
        path = "item.where(linkId = '3').item.where(linkId = '3.1').answer.where(value is Coding).value.code"
        eval_result = evaluate_fhirpath(questionnaire_response, path)
        elem = eval_result.first&.dig('element')
        elem&.parameterize&.underscore
      end

      # Wrapper around evaluator call. The SuiteEndpoint isn't a runnable, so we just instantiate a dummy runnable
      def evaluate_fhirpath(fhir_resource, fhirpath_expression)
        evaluator.evaluate_fhirpath(fhir_resource, fhirpath_expression, Inferno::TestSuite.new)
      end
    end
  end
end
