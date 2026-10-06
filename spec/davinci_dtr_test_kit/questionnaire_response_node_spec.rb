require 'davinci_dtr_test_kit/cross_suite/v2.2.0/questionnaire_response_node'

RSpec.describe DaVinciDTRTestKit::QuestionnaireResponseNode do
  def item(link_id, value = nil)
    FHIR::QuestionnaireResponse::Item.new(
      linkId: link_id,
      answer: value.nil? ? [] : [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: value)]
    )
  end

  def root_for(items)
    described_class.root(FHIR::QuestionnaireResponse.new(status: 'in-progress', item: items))
  end

  describe '#item_children_by_link_id' do
    it 'groups the item children by their link id' do
      root = root_for([item('Q1', 'a'), item('Q2', 'b')])

      expect(root.item_children_by_link_id.keys).to eq(%w[Q1 Q2])
      expect(root.item_children_by_link_id['Q1'].map(&:link_id)).to eq(['Q1'])
    end

    it 'is built once and reused' do
      root = root_for([item('Q1', 'a')])
      first_call = root.item_children_by_link_id

      expect(root.item_children_by_link_id).to be(first_call)
    end
  end

  describe '#item_children_with_link_id' do
    it 'returns the children with that link id' do
      root = root_for([item('Q1', 'a'), item('Q2', 'b')])

      expect(root.item_children_with_link_id('Q1').map { |child| child.payload.answer.first.value }).to eq(['a'])
    end

    it 'returns every occurrence of a repeated link id, in order' do
      root = root_for([item('Q1', 'first'), item('Q2', 'other'), item('Q1', 'second')])

      answers = root.item_children_with_link_id('Q1').map { |child| child.payload.answer.first.value }
      expect(answers).to eq(%w[first second])
    end

    # Callers iterate the result, so an unknown link id has to come back as an empty list
    it 'returns an empty list for a link id that is not there' do
      root = root_for([item('Q1', 'a')])

      expect(root.item_children_with_link_id('nope')).to eq([])
    end

    it 'returns an empty list when the response has no items at all' do
      expect(root_for([]).item_children_with_link_id('Q1')).to eq([])
    end

    it 'does not return the answers of an item as item children' do
      root = root_for([item('Q1', 'a')])
      question = root.item_children_with_link_id('Q1').first

      expect(question.answer_children.length).to eq(1)
      expect(question.item_children_with_link_id('Q1')).to eq([])
    end
  end
end
