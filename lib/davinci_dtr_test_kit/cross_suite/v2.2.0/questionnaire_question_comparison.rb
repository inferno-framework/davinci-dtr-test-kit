require_relative 'questionnaire_response_checker'

module DaVinciDTRTestKit
  # Compares the Questionnaire a client sent within a `$next-question` request against the one the
  # payer returned to it. A client is expected to send back the questions it was given, adding only
  # answers, so a question that has been dropped, added or altered is reported. Dropping a question,
  # or attaching a condition that turns it off, would otherwise be a way to avoid answering it.
  class QuestionnaireQuestionComparison
    Finding = QuestionnaireResponseChecker::Finding

    DESCRIPTIONS = {
      question_removed: 'was returned by the payer but is missing from the Questionnaire in this request',
      question_added: 'is in the Questionnaire in this request but was not returned by the payer',
      question_altered: 'differs from the question the payer returned'
    }.freeze

    # The parts of a question that decide whether it has to be answered
    COMPARED_ATTRIBUTES = {
      'type' => :type.to_proc,
      'required' => :required.to_proc,
      'enableBehavior' => :enableBehavior.to_proc,
      'enableWhen' => ->(item) { Array(item.enableWhen).map(&:to_hash) },
      'enableWhenExpression' => lambda { |item|
        Array(item.extension)
          .select { |extension| extension.url == QuestionnaireResponseChecker::ENABLE_WHEN_EXPRESSION_URL }
          .map(&:to_hash)
      }
    }.freeze

    def initialize(returned_questionnaire, request_questionnaire)
      @returned_questionnaire = returned_questionnaire
      @request_questionnaire = request_questionnaire
    end

    def findings
      return @findings if @findings

      @findings = []
      report_removed_and_altered
      report_added
      @findings
    end

    private

    # Questions come parent first, so a branch that went missing whole is reported at its top rather
    # than once for every question within it.
    def report_removed_and_altered
      removed = []
      returned_questions.each do |location, returned_item|
        next if within?(removed, location)

        request_item = request_questions[location]
        if request_item.nil?
          removed << location
          add_finding(:question_removed, location)
        else
          altered = differing_attributes(returned_item, request_item)
          add_finding(:question_altered, location, altered) if altered.any?
        end
      end
    end

    def report_added
      added = []
      (request_questions.keys - returned_questions.keys).each do |location|
        next if within?(added, location)

        added << location
        add_finding(:question_added, location)
      end
    end

    def within?(reported_locations, location)
      reported_locations.any? do |reported|
        location.length > reported.length && location.first(reported.length) == reported
      end
    end

    def returned_questions
      @returned_questions ||= questions_by_location(@returned_questionnaire)
    end

    def request_questions
      @request_questions ||= questions_by_location(@request_questionnaire)
    end

    # Every question in the questionnaire, keyed by where it sits, so that questions are compared
    # where they belong rather than by link id alone.
    def questions_by_location(questionnaire, items = nil, path = [], found = {})
      occurrences = Hash.new(0)
      Array(items || questionnaire&.item).each do |item|
        occurrences[item.linkId] += 1
        label = occurrences[item.linkId] > 1 ? "#{item.linkId}[#{occurrences[item.linkId]}]" : item.linkId
        found[path + [label]] = item
        questions_by_location(questionnaire, Array(item.item), path + [label], found)
      end
      found
    end

    def differing_attributes(returned_item, request_item)
      COMPARED_ATTRIBUTES.filter_map do |name, read|
        name unless read.call(returned_item) == read.call(request_item)
      end
    end

    def add_finding(type, location, altered = [])
      link_id = location.last
      within = location[0..-2]
      where = within.empty? ? '' : " within `#{within.join(' > ')}`"
      detail = altered.empty? ? '' : " (#{altered.join(', ')})"
      @findings << Finding.new(type, :error, link_id, within.join(' > '),
                               "Item `#{link_id}`#{where} #{DESCRIPTIONS[type]}#{detail}.")
    end
  end
end
