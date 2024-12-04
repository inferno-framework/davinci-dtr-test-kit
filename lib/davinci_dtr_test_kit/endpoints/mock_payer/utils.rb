module DaVinciDTRTestKit
  module MockPayer
    module Utils
      def parse_fhir_object(str)
        FHIR.from_contents(str)
      rescue StandardError
        operation_outcome('error', 'invalid', 'No valid input parameters')
      end

      def find_questionnaire_response(input_parameters)
        questionnaire_response_param = input_parameters.try(&:parameter)&.find do |param|
          param.name == 'questionnaire-response'
        end
        return questionnaire_response_param if questionnaire_response_param

        operation_outcome('error', 'business-rule',
                          'Input parameter does not have a `parameter:questionnaire-response` slice.')
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
    end
  end
end
