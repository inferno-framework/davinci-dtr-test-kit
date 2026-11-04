module DaVinciDTRTestKit
  # Shared logic for the DTR v2.2.0 answer origin scenario.
  #
  # A Questionnaire item is considered "pre-populated" when it carries an SDC initialExpression,
  # calculatedExpression, or candidateExpression, since the DTR client is expected to fill those in by
  # executing CQL. Answers to pre-populated items should have an information-origin source of
  # 'auto-client' / 'auto-server', or 'override' once a user changes them. All other answers are
  # expected to have a source of 'manual'.
  module AnswerOriginHelper
    INFORMATION_ORIGIN_URL = 'http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/information-origin'.freeze

    INITIAL_EXPRESSION_URL = 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'.freeze
    CALCULATED_EXPRESSION_URL =
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-calculatedExpression'.freeze
    CANDIDATE_EXPRESSION_URL =
      'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-candidateExpression'.freeze
    PREPOPULATION_EXPRESSION_URLS = [INITIAL_EXPRESSION_URL, CALCULATED_EXPRESSION_URL, CANDIDATE_EXPRESSION_URL].freeze

    def prepopulated_item?(questionnaire_item)
      return false if questionnaire_item.nil?

      questionnaire_item.extension.any? do |extension|
        PREPOPULATION_EXPRESSION_URLS.include?(extension.url)
      end
    end

    # Returns every item in a Questionnaire item tree, including nested items.
    def all_questionnaire_items(items)
      all_items = []
      items.each do |item|
        all_items << item
        all_items.concat(all_questionnaire_items(item.item))
      end
      all_items
    end
  end
end
