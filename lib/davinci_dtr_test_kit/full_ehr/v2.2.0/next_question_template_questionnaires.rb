module DaVinciDTRTestKit
  # Shared by the $next-question mock endpoint and the interaction wait test so that both agree
  # on what counts as a usable $next-question response template: a single Questionnaire or a
  # JSON array of Questionnaires. Entries that do not parse to a FHIR Questionnaire are silently
  # discarded rather than treated as an error, since a template array may intentionally carry
  # entries meant for other questionnaires in the workflow.
  module NextQuestionTemplateQuestionnaires
    def questionnaires_from_template_value(value)
      parsed_json = JSON.parse(value)
      questionnaire_jsons = parsed_json.is_a?(Array) ? parsed_json : [parsed_json]
      questionnaire_jsons.filter_map { |questionnaire_json| parse_template_questionnaire(questionnaire_json) }
    end

    def parse_template_questionnaire(questionnaire_json)
      parsed = FHIR.from_contents(questionnaire_json.to_json)
      parsed if parsed.is_a?(FHIR::Questionnaire)
    rescue StandardError
      nil
    end
  end
end
