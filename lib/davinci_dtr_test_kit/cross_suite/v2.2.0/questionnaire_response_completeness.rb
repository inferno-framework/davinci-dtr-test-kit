require_relative 'questionnaire_response_checker'

module DaVinciDTRTestKit
  # Checks a QuestionnaireResponse against the Questionnaire it is based on. Used by Inferno's
  # simulated payer server to decide when a QuestionnaireResponse for an adaptive form is complete,
  # and by the client tests to verify that a client does not ask for the next question until the
  # current questions have been answered.
  #
  # Whether a question needs an answer depends on its `enableWhen` conditions: a question that is not
  # enabled is not required, and neither are the questions nested within it. `required` also only
  # applies once the item holding the question is present, so the questions within an optional group
  # need answers only when that group is answered. See QuestionnaireResponseChecker for the details.
  module QuestionnaireResponseCompleteness
    # Every way in which the QuestionnaireResponse does not line up with the Questionnaire, as
    # QuestionnaireResponseChecker::Finding structs.
    def questionnaire_response_findings(questionnaire, questionnaire_response)
      QuestionnaireResponseChecker.new(questionnaire, questionnaire_response).findings
    end

    # True when every required question that is enabled has an answer. The other findings describe a
    # QuestionnaireResponse that does not match its Questionnaire rather than one that is unfinished,
    # so they do not keep it from being considered complete.
    def questionnaire_response_complete?(questionnaire, questionnaire_response)
      questionnaire_response_findings(questionnaire, questionnaire_response)
        .none? { |finding| finding.type == :required_unanswered }
    end
  end
end
