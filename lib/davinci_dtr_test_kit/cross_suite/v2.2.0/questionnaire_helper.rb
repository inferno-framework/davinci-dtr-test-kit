module DaVinciDTRTestKit
  module QuestionnaireHelper
    ###########################################################################
    # Canonical URLs
    ###########################################################################

    def questionnaire_canonical_url(questionnaire)
      if questionnaire.version.present?
        "#{questionnaire.url}|#{questionnaire.version}"
      else
        questionnaire.url
      end
    end

    ###########################################################################
    # Categorizing Questionnaires
    ###########################################################################

    def adaptive_questionnaire?(questionnaire)
      questionnaire.extension.find do |extension|
        extension.valueBoolean != false &&
          extension.url == 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-questionnaireAdaptive'
      end
    end

    ###########################################################################
    # Display for Questionnaires
    ###########################################################################

    def questionnaire_display(questionnaire)
      canonical_url = questionnaire_canonical_url(questionnaire)
      title = questionnaire.title.present? ? questionnaire.title : questionnaire.name

      if title.present?
        "#{title} (#{canonical_url})"
      else
        canonical_url
      end
    end

    ###########################################################################
    # Generic Questionnaire Extraction ($questionnaire-package or $next-question)
    ###########################################################################

    def no_questionnaires_returned?(requests)
      questionnaires_from_operation_responses(requests).blank?
    end

    def questionnaires_from_operation_responses(requests, include_standard: true, include_adaptive: true)
      questionnaires = []

      parsed_operation_responses(requests).each do |request, response|
        # pull out Questionnaires from requests ($q-p and $n-q)
        if response.is_a?(FHIR::QuestionnaireResponse)
          questionnaires << contained_questionnaire_from_questionnaire_response(response) if include_adaptive
        elsif response.is_a?(FHIR::Parameters)
          questionnaires.concat(questionnaires_from_operation_response_parameters(response, request, include_standard:,
                                                                                                     include_adaptive:))
        end
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

    ###########################################################################
    # $next-question extraction of QuestionnaireResponse and Questionnaire
    ###########################################################################

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

    # $next-question has a single "return" out parameter typed as a Resource, so per the FHIR
    # spec (https://www.hl7.org/fhir/R4/operations.html#response) a conformant response is the
    # raw QuestionnaireResponse rather than a Parameters wrapper (see
    # dtr_next_question_response_validation_test); a Parameters-wrapped `return` is tolerated too.
    # Expects an already-parsed response body (a FHIR resource), not a raw request/JSON string.
    def questionnaire_response_from_next_question_response(response_body)
      case response_body
      when FHIR::QuestionnaireResponse
        response_body
      when FHIR::Parameters
        response_body.parameter.find do |parameter|
          parameter.name == 'return' && parameter.resource.is_a?(FHIR::QuestionnaireResponse)
        end&.resource
      end
    end

    def questionnaire_response_from_next_question_request(request_body)
      case request_body
      when FHIR::QuestionnaireResponse
        request_body
      when FHIR::Parameters
        request_body.parameter.find do |parameter|
          parameter.name == 'questionnaire-response' && parameter.resource.is_a?(FHIR::QuestionnaireResponse)
        end&.resource
      end
    end

    ###########################################################################
    # $questionnaire-package extraction of Parameters, Bundle, Questionnaire
    ###########################################################################

    def questionnaire_package_output_parameters_from_operation_responses(requests)
      parsed_operation_responses(requests).filter_map do |_request, response|
        response if response.is_a?(FHIR::Parameters)
      end
    end

    def questionnaire_package_bundles(parameters)
      parameters.parameter.filter_map do |parameter|
        parameter.resource if parameter.name == 'packagebundle' && parameter.resource.is_a?(FHIR::Bundle)
      end
    end

    def questionnaires_from_questionnaire_package_output_parameters(parameters, include_standard: true,
                                                                    include_adaptive: true)
      questionnaire_package_bundles(parameters).filter_map do |bundle|
        questionnaire_from_package_bundle(bundle, include_standard:, include_adaptive:)
      end
    end

    def questionnaire_from_package_bundle(bundle, include_standard: true, include_adaptive: true)
      bundle.entry.find do |entry|
        entry.resource.is_a?(FHIR::Questionnaire) &&
          (adaptive_questionnaire?(entry.resource) ? include_adaptive : include_standard)
      end&.resource
    end

    private

    def parsed_operation_responses(requests)
      requests.filter_map do |request|
        next if request.response_body.blank?

        [request, FHIR.from_contents(request.response_body)]
      rescue JSON::ParserError
        nil # errors handled elsewhere
      end
    end
  end
end
