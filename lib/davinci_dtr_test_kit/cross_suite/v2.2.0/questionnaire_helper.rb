module DaVinciDTRTestKit
  module QuestionnaireHelper
    def contained_questionnaire_from_questionnaire_response(questionnaire_response)
      questionnaire_response&.contained&.find do |contained_resource|
        contained_resource.is_a?(FHIR::Questionnaire)
      end
    end

    def questionnaire_from_next_question_output_parameters(parameters)
      return_parameter = parameters.parameter.find do |parameter|
        parameter.name == 'return' && parameter.resource.is_a?(FHIR::QuestionnaireResponse)
      end
      return nil unless return_parameter.present?

      contained_questionnaire_from_questionnaire_response(return_parameter.resource)
    end

    def questionnaires_from_questionnaire_package_output_parameters(parameters, include_standard: true,
                                                                    include_adaptive: true)
      parameters.parameter.select { |parameter| parameter.name == 'packagebundle' && parameter.resource.is_a?(FHIR::Bundle) }
        .map do |parameter|
          questionnaire_from_package_bundle(parameter.resource, include_standard:, include_adaptive:)
        end.compact
    end

    def questionnaire_from_package_bundle(bundle, include_standard: true, include_adaptive: true)
      bundle.entry.find do |entry|
        entry.resource.is_a?(FHIR::Questionnaire) &&
          (adaptive_questionnaire?(entry.resource) ? include_adaptive : include_standard)
      end&.resource
    end

    def adaptive_questionnaire?(questionnaire)
      questionnaire.extension.find do |extension|
        extension.valueBoolean != false &&
          extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'
      end
    end

    def questionnaires_from_operation_responses(requests, include_standard: true, include_adaptive: true)
      questionnaires = []

      requests.each do |request|
        # pull out Questionnaires from requests ($q-p and $n-q)
        response = FHIR.from_contents(request.response_body)
        if response.is_a?(FHIR::QuestionnaireResponse)
          questionnaires << contained_questionnaire_from_questionnaire_response(response) if include_adaptive
        elsif response.is_a?(FHIR::Parameters)
          questionnaires.concat(questionnaires_from_operation_response_parameters(response, request, include_standard:,
                                                                                                     include_adaptive:))
        end
      rescue JSON::ParserError
        next # errors handled elsewhere
      end

      questionnaires.compact
    end

    def questionnaires_from_operation_response_parameters(parameters, request, include_standard: true,
                                                          include_adaptive: true)
      if request.url.include?('$questionnaire-package')
        questionnaires_from_questionnaire_package_output_parameters(parameters, include_standard:, include_adaptive:)
      elsif request.url.include?('$next-question')
        Array.wrap(include_adaptive ? questionnaire_from_next_question_output_parameters(parameters) : nil)
      end
    end
  end
end
