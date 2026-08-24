module DaVinciDTRTestKit
  # A navigable view of a QuestionnaireResponse. Each node wraps either the resource itself, one of
  # its items, or one of an item's answers, and knows its parent and its index within it, so that a
  # position within the response can be described and searched from.
  #
  # The children of an item are its answers followed by its nested items, matching the order in which
  # those elements appear in the resource.
  class QuestionnaireResponseNode
    attr_reader :kind, :payload, :parent, :index_in_parent

    def self.root(questionnaire_response)
      new(kind: :root, payload: questionnaire_response)
    end

    # A stand-in for an item that the response does not contain, holding the place it would occupy
    # among the given parent's children so that questions within it still have a position.
    def self.absent_item(link_id, parent:, index_in_parent:)
      new(kind: :item, payload: FHIR::QuestionnaireResponse::Item.new(linkId: link_id), parent:,
          index_in_parent:, virtual: true)
    end

    def initialize(kind:, payload:, parent: nil, index_in_parent: nil, virtual: false)
      @kind = kind
      @payload = payload
      @parent = parent
      @index_in_parent = index_in_parent
      @virtual = virtual
    end

    def item?
      kind == :item
    end

    # True when this node stands in for an item that is not in the response. Its index is the place it
    # would occupy, so the sibling at that index follows it rather than precedes it.
    def virtual?
      @virtual
    end

    def answer?
      kind == :answer
    end

    def link_id
      payload.linkId if item?
    end

    # The answers of an item node, in the order that they appear
    def answers
      item? ? Array(payload.answer) : []
    end

    def answer_values
      answers.map(&:value).compact
    end

    # True when this node is an answer that has a value. An answer value of `false` is a valid
    # answer, so this checks for nil rather than presence.
    def answered?
      answer? && !payload.value.nil?
    end

    def children
      @children ||= build_children
    end

    def item_children
      children.select(&:item?)
    end

    def answer_children
      children.select(&:answer?)
    end

    def item_children_with_link_id(target_link_id)
      item_children.select { |child| child.link_id == target_link_id }
    end

    # True when any descendant of this node is an answer with a value
    def answered_descendant?
      children.any? { |child| child.answered? || child.answered_descendant? }
    end

    # This node followed by its descendants, in document order
    def self_and_descendants
      [self] + children.flat_map(&:self_and_descendants)
    end

    # This node followed by its descendants, with the children of each node visited in reverse order.
    # Used when walking backwards from a position so that nearer nodes come first.
    def self_and_descendants_reversed
      [self] + children.reverse.flat_map(&:self_and_descendants_reversed)
    end

    private

    # An item's answers come before its nested items, matching the order of the elements in the
    # resource. The resource itself and an answer only hold nested items.
    def build_children
      return answer_nodes + item_nodes(Array(payload.item), answers.length) if item?

      item_nodes(Array(payload.item), 0)
    end

    def answer_nodes
      answers.each_with_index.map do |answer, index|
        self.class.new(kind: :answer, payload: answer, parent: self, index_in_parent: index)
      end
    end

    def item_nodes(items, index_offset)
      items.each_with_index.map do |item, index|
        self.class.new(kind: :item, payload: item, parent: self, index_in_parent: index + index_offset)
      end
    end
  end

  # A location within a QuestionnaireResponse, either of a node that is present or of the place where
  # a missing item would be. Used to resolve the question referenced by an `enableWhen` condition
  # relative to where the question being evaluated is, or would be, answered.
  class QuestionnaireResponsePosition
    attr_reader :parent, :before_index, :after_index

    # The position occupied by an existing node
    def self.at(node)
      new(parent: node.parent, before_index: node.index_in_parent, after_index: node.index_in_parent + 1)
    end

    # The position a missing item would occupy among the children of the given node
    def self.within(parent, index)
      new(parent:, before_index: index, after_index: index)
    end

    def initialize(parent:, before_index:, after_index:)
      @parent = parent
      @before_index = before_index
      @after_index = after_index
    end

    # The nodes that come before this position, nearest first: each preceding sibling followed by its
    # descendants in reverse order, then the siblings preceding the parent, and so on outwards.
    # Ancestors are not included because they are searched separately.
    def preceding_nodes
      nodes = []
      node = parent
      index = before_index
      while node
        (index - 1).downto(0) do |sibling_index|
          nodes.concat(node.children[sibling_index].self_and_descendants_reversed)
        end
        index = node.index_in_parent
        node = node.parent
      end
      nodes
    end

    # The nodes that come after this position, nearest first: each following sibling followed by its
    # descendants in document order, then the siblings following the parent, and so on outwards.
    def following_nodes
      nodes = []
      node = parent
      index = after_index
      while node
        index.upto(node.children.length - 1) do |sibling_index|
          nodes.concat(node.children[sibling_index].self_and_descendants)
        end
        index = node.index_in_parent.to_i + (node.virtual? ? 0 : 1)
        node = node.parent
      end
      nodes
    end
  end
end
