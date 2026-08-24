require_relative 'enable_when_comparison'
require_relative 'questionnaire_response_node'

module DaVinciDTRTestKit
  # Walks a Questionnaire and a QuestionnaireResponse together, reporting the places where the
  # response does not line up with the questionnaire: required questions that are enabled but have no
  # answer, questions that have been answered even though they are not enabled, and answers or nested
  # items that are not where the questionnaire's item types say they belong.
  #
  # The two resources are walked in parallel because whether a question is enabled, and whether it is
  # required, depends on where in the response the question is, or would be, answered. A repeating
  # question with nested questions is the case that makes this necessary: within one answer of the
  # repeating question, a condition referencing that question resolves to that single answer rather
  # than to all of them.
  class QuestionnaireResponseChecker
    Finding = Struct.new(:type, :link_id, :path, :message)

    # An ancestor of the position being evaluated. When the walk steps into one answer of a question,
    # the ancestor holds only that answer, so that a condition referencing the question resolves to
    # the answer the walk is inside of.
    Ancestor = Struct.new(:link_id, :answer_values)

    DESCRIPTIONS = {
      required_unanswered: 'is required and enabled, but has no answer',
      answered_while_disabled: 'has an answer, but is not enabled based on its `enableWhen` condition(s)',
      group_with_answers: 'is a group, so it must not have answers',
      items_outside_answer: 'is not a group, so its nested items must appear within its answers'
    }.freeze

    def initialize(questionnaire, questionnaire_response)
      @questionnaire = questionnaire
      @questionnaire_response = questionnaire_response
    end

    def findings
      return @findings if @findings

      @findings = []
      check_level(Array(@questionnaire.item), QuestionnaireResponseNode.root(@questionnaire_response),
                  ancestors: [], path: [])
      @findings
    end

    private

    # Checks each item defined at this level of the questionnaire against the matching items at this
    # level of the response.
    def check_level(item_definitions, response_node, ancestors:, path:)
      definition_order = item_definitions.each_with_index.to_h { |item, index| [item.linkId, index] }
      item_definitions.each do |item|
        occurrences = response_node.item_children_with_link_id(item.linkId)
        if occurrences.empty?
          check_missing_item(item, response_node, definition_order, ancestors:, path:)
        else
          check_occurrences(item, occurrences, ancestors:, path:)
        end
      end
    end

    # An item with no matching response item is evaluated from the position it would occupy had it been
    # answered.
    def check_missing_item(item, response_node, definition_order, ancestors:, path:)
      index = insertion_index(item, response_node, definition_order)
      return unless item_enabled?(item, QuestionnaireResponsePosition.within(response_node, index), ancestors)

      add_finding(:required_unanswered, item, path) if item.required == true
      return unless descend_into_absent_group?(item)

      absent_group = QuestionnaireResponseNode.absent_item(item.linkId,
                                                           parent: response_node, index_in_parent: index)
      check_group_children(item, absent_group, item.linkId, ancestors:, path:)
    end

    # A group holds no answers of its own, so its absence from the response is a consequence of the
    # questions within it being unanswered rather than a statement that they do not apply, and those
    # questions are still checked. A repeating group is the exception: with no repetition present there
    # is nothing for its questions to belong to.
    def descend_into_absent_group?(item)
      group?(item) && item.repeats != true
    end

    def check_occurrences(item, occurrences, ancestors:, path:)
      occurrences.each_with_index do |occurrence, index|
        # A repeating group appears as several response items with the same linkId, and each of them
        # is evaluated on its own because they occupy different positions.
        segment = occurrences.length > 1 ? "#{item.linkId}[#{index + 1}]" : item.linkId
        check_occurrence(item, occurrence, segment, ancestors:, path:)
      end
    end

    def check_occurrence(item, occurrence, segment, ancestors:, path:)
      enabled = item_enabled?(item, QuestionnaireResponsePosition.at(occurrence), ancestors)
      check_enabled_and_required(item, enabled, present?(item, occurrence), path)
      return unless enabled

      # A group is descended into whether or not it holds an answer yet, because its own presence
      # depends on the questions within it. A question's nested items live within its answers, so
      # there is nothing to descend into until it has one.
      if group?(item)
        check_group_children(item, occurrence, segment, ancestors:, path:)
      else
        check_question_children(item, occurrence, segment, ancestors:, path:)
      end
    end

    def check_enabled_and_required(item, enabled, present, path)
      if enabled
        add_finding(:required_unanswered, item, path) if item.required == true && !present
      elsif present
        add_finding(:answered_while_disabled, item, path)
      end
    end

    # A group is answered through its nested items, so the walk continues into the response item.
    def check_group_children(item, occurrence, segment, ancestors:, path:)
      add_finding(:group_with_answers, item, path) if occurrence.answers.any?

      check_level(Array(item.item), occurrence,
                  ancestors: ancestors + [Ancestor.new(item.linkId, occurrence.answer_values)],
                  path: path + [segment])
    end

    # A question's nested items belong to its answers, so the walk continues into each answer
    # separately, with the ancestor narrowed to that one answer.
    def check_question_children(item, occurrence, segment, ancestors:, path:)
      add_finding(:items_outside_answer, item, path) if occurrence.item_children.any?

      answer_nodes = occurrence.answer_children
      answer_nodes.each_with_index do |answer_node, index|
        answer_segment = answer_nodes.length > 1 ? "#{segment}[answer #{index + 1}]" : segment
        check_level(Array(item.item), answer_node,
                    ancestors: ancestors + [answer_ancestor(item, answer_node)],
                    path: path + [answer_segment])
      end
    end

    def answer_ancestor(item, answer_node)
      Ancestor.new(item.linkId, [answer_node.payload.value].compact)
    end

    # A group is present when one of its descendants holds an answer, a question when it has an answer
    # of its own. `answer_values` has already had answers without a value removed, and an answer value
    # of `false` must count, so presence is emptiness of that list rather than its truthiness.
    def present?(item, occurrence)
      group?(item) ? occurrence.answered_descendant? : !occurrence.answer_values.empty?
    end

    def group?(item)
      item.type == 'group'
    end

    # The index a missing item would occupy among the response node's children, based on the order in
    # which the questions are defined in the questionnaire.
    def insertion_index(item, response_node, definition_order)
      target_index = definition_order[item.linkId]
      following_child = response_node.children.index do |child|
        next false unless child.item?

        child_index = definition_order[child.link_id]
        !child_index.nil? && child_index > target_index
      end
      following_child || response_node.children.length
    end

    # ***********************************************************************
    # enableWhen evaluation
    # ***********************************************************************

    def item_enabled?(item, position, ancestors)
      conditions = Array(item.enableWhen)
      return true if conditions.empty?

      results = conditions.map { |condition| condition_met?(condition, position, ancestors) }
      item.enableBehavior == 'all' ? results.all? : results.any?
    end

    def condition_met?(condition, position, ancestors)
      answer_values = resolve_answer_values(condition.question, position, ancestors)
      return !answer_values.empty? == (condition.answer == true) if condition.operator == 'exists'

      answer_values.any? do |answer_value|
        EnableWhenComparison.met?(condition.operator, answer_value, condition.answer)
      end
    end

    # Resolves the answers of the question a condition references, using the first item found while
    # searching the ancestors of the position, then the nodes preceding it, then the nodes following
    # it.
    def resolve_answer_values(link_id, position, ancestors)
      ancestor = ancestors.reverse.find { |candidate| candidate.link_id == link_id }
      return ancestor.answer_values if ancestor

      match = find_item_node(position.preceding_nodes, link_id) || find_item_node(position.following_nodes, link_id)
      match ? match.answer_values : []
    end

    def find_item_node(nodes, link_id)
      nodes.find { |node| node.item? && node.link_id == link_id }
    end

    # ***********************************************************************
    # Findings
    # ***********************************************************************

    def add_finding(type, item, path)
      location = path.empty? ? '' : " within `#{path.join(' > ')}`"
      @findings << Finding.new(type, item.linkId, path.join(' > '),
                               "Item `#{item.linkId}`#{location} #{DESCRIPTIONS[type]}.")
    end
  end
end
