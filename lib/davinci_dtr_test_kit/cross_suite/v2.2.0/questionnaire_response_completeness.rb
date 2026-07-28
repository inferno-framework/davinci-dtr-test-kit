module DaVinciDTRTestKit
  # Determines whether a QuestionnaireResponse has answers for all of the required questions in the
  # Questionnaire that it is based on. Used by Inferno's simulated payer server to decide when a
  # QuestionnaireResponse for an adaptive form is complete, and by the client tests to verify that a
  # client does not ask for the next question until the current questions have been answered.
  #
  # Note that this logic does not take `enableWhen` conditions into account: a required question is
  # expected to be answered even when its enabling condition is not met.
  module QuestionnaireResponseCompleteness
    # The Questionnaire contained within a QuestionnaireResponse, which for an adaptive form holds
    # the questions disclosed so far.
    def contained_questionnaire(questionnaire_response)
      questionnaire_response.contained&.find { |contained_resource| contained_resource.is_a?(FHIR::Questionnaire) }
    end

    def questionnaire_response_complete?(questionnaire, questionnaire_response)
      unanswered_required_link_ids(questionnaire, questionnaire_response).empty?
    end

    # The link ids of the required questions in the questionnaire that do not have an answer in the
    # questionnaire response. Questions nested within an unanswered required question are omitted.
    def unanswered_required_link_ids(questionnaire, questionnaire_response)
      Array(questionnaire.item).flat_map do |item|
        unanswered_required_link_ids_for_item(item, questionnaire_response.item)
      end
    end

    private

    def unanswered_required_link_ids_for_item(item, response_items)
      response_item = find_response_item(item, response_items)
      return [item.linkId] if required_and_unanswered?(item, response_item)

      Array(item.item).flat_map do |sub_item|
        unanswered_required_link_ids_for_item(sub_item, response_item&.item)
      end
    end

    def find_response_item(item, response_items)
      Array(response_items).find { |response_item| response_item.linkId == item.linkId }
    end

    def required_and_unanswered?(item, response_item)
      item.required == true && !answer_present?(response_item)
    end

    def answer_present?(response_item)
      # an answer value of `false` is a valid answer, so check for nil rather than presence
      Array(response_item&.answer).any? { |answer| !answer&.value.nil? }
    end
  end
end
