require_relative '../../../urls'
require_relative '../../../cross_suite/v2.2.0/multi_request_message_helper'
require_relative '../../short_circuit_interaction_verification'
require_relative '../../../cross_suite/v2.2.0/questionnaire_helper'

module DaVinciDTRTestKit
  class DTRFullEHRV220AdaptiveQuestionnairesCompletedTest < Inferno::Test
    include URLs
    include MultiRequestMessageHelper
    include ShortCircuitInteractionVerification
    include QuestionnaireHelper

    id :dtr_full_ehr_v220_adaptive_questionnaires_completed
    title 'Adaptive Questionnaires Completed'
    description %(
      This test validates that all adaptive Questionnaires returned by Inferno during
      this interaction were completed as shown by a $next-question request where Inferno
      updated the status of the QuestionnaireResponse to `completed`.
    )

    def target_qp_tags
      tags = [QUESTIONNAIRE_PACKAGE_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def target_nq_tags
      tags = [CLIENT_NEXT_TAG]
      tags << config.options[:dtr_workflow_tag] if config.options[:dtr_workflow_tag].present?

      tags
    end

    def adaptive_questionnaire_canonicals
      @adaptive_questionnaire_canonicals ||=
        load_tagged_requests(*target_qp_tags).each_with_object([]) do |request, adaptive_questionnaires|
          request_parameters = FHIR.from_contents(request.response_body)
          next unless request_parameters.is_a?(FHIR::Parameters)

          adaptive_questionnaires.concat(
            questionnaires_from_questionnaire_package_output_parameters(request_parameters, include_standard: false)
              .map { |questionnaire| questionnaire_canonical_url(questionnaire) }
          )
        rescue JSON::ParserError
          next
        end
    end

    def completed_questionnaire_canonicals
      @completed_questionnaire_canonicals ||=
        load_tagged_requests(*target_nq_tags).each_with_object([]) do |request, completed_questionnaires|
          contained_questionnaire = completed_contained_questionnaire(request)
          next unless contained_questionnaire.present?

          completed_questionnaires << questionnaire_canonical_url(contained_questionnaire)
        rescue JSON::ParserError
          next
        end
    end

    # Returns the contained Questionnaire from a $next-question response's QuestionnaireResponse,
    # but only when Inferno marked that QuestionnaireResponse `completed` -- an in-progress adaptive
    # workflow hasn't finished yet.
    def completed_contained_questionnaire(request)
      response_questionnaire_response = questionnaire_response_from_next_question_response(request)
      return nil unless response_questionnaire_response.present?
      return nil unless response_questionnaire_response.status == 'completed'

      contained_questionnaire_from_questionnaire_response(response_questionnaire_response)
    end

    run do
      check_for_short_circuit(ok_message: config.options[:short_circuit_pass_message])

      pass_if adaptive_questionnaire_canonicals.blank?, 'No adaptive Questionnaires returned.'

      adaptive_questionnaire_canonicals.each do |target_canonical|
        next if completed_questionnaire_canonicals.include?(target_canonical)

        add_message('error', "Adaptive Questionnaire with canonical url `#{target_canonical}` was never completed.")
      end

      assert_no_error_messages(
        'Adaptive Questionnaires retrieved but not completed. See Messages for details.'
      )
    end
  end
end
