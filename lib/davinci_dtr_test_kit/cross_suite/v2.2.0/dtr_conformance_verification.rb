require_relative 'multi_request_message_helper'

module DaVinciDTRTestKit
  module DTRConformanceVerification
    include MultiRequestMessageHelper

    def check_questionnaire_response_conformance(questionnaire_response_json, message_index,
                                                 target_profile_with_version)
      questionnaire_response = parse_fhir_request_entity(questionnaire_response_json, 'QuestionnaireResponse',
                                                         message_index)
      return unless questionnaire_response.present?

      unless questionnaire_response.is_a?(FHIR::QuestionnaireResponse)
        add_request_message('error',
                            "Expected a QuestionnaireResponse, found a #{questionnaire_response.resourceType}.")
      end

      resource_is_valid?(resource: questionnaire_response, profile_url: target_profile_with_version)
    end
  end
end
