require_relative '../mock_authorization/common'
require_relative '../../fixtures'
require_relative 'utils'

module DaVinciDTRTestKit
  module MockPayer
    class QuestionnairePackageEndpoint < Inferno::DSL::SuiteEndpoint
      include Utils

      def test_run_identifier
        MockAuthorization.extract_client_id_from_bearer_token(request)
      end

      def tags
        [QUESTIONNAIRE_PACKAGE_TAG]
      end

      def make_response
        response.status = 200
        response.format = :json
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.body = build_questionnaire_package_response.to_json
      end

      private

      def build_questionnaire_package_response
        input_parameters = parse_fhir_object(request.body.string)
        return input_parameters if input_parameters.is_a?(FHIR::OperationOutcome)

        questionnaire_package = Fixtures.questionnaire_package_for_test(test.id)
        unless questionnaire_package
          return operation_outcome('error', 'business-rule', "No Questionnaire found for Inferno test #{test.id}")
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

        FHIR::Parameters.new(parameter: [package_bundle_param, outcome_param])
      end

      def find_questionnaire_canonical(questionnaire_package)
        questionnaire_package&.entry&.find { |e| e.resource.is_a?(FHIR::Questionnaire) }&.resource&.url
      end
    end
  end
end
