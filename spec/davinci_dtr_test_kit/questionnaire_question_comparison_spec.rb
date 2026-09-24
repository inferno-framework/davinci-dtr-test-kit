require 'davinci_dtr_test_kit/cross_suite/v2.2.0/questionnaire_question_comparison'

RSpec.describe DaVinciDTRTestKit::QuestionnaireQuestionComparison do
  def questionnaire(items)
    FHIR::Questionnaire.new(status: 'draft', item: items)
  end

  def question(link_id, attributes = {})
    FHIR::Questionnaire::Item.new({ linkId: link_id, type: 'string' }.merge(attributes))
  end

  def summarize(returned, sent)
    described_class.new(returned, sent).findings.map { |finding| [finding.type, finding.link_id, finding.path] }
  end

  it 'returns no findings when the client sends back the questions it was given' do
    returned = questionnaire([question('Q1', required: true), question('Q2')])
    sent = questionnaire([question('Q1', required: true), question('Q2')])

    expect(described_class.new(returned, sent).findings).to be_empty
  end

  it 'reports a question the client dropped' do
    returned = questionnaire([question('Q1', required: true), question('Q2')])
    sent = questionnaire([question('Q2')])

    findings = described_class.new(returned, sent).findings

    expect(summarize(returned, sent)).to eq([[:question_removed, 'Q1', '']])
    expect(findings.first.message).to eq(
      'Item `Q1` was returned by the payer but is missing from the Questionnaire in this request.'
    )
    expect(findings.first.severity).to eq(:error)
  end

  it 'reports a question the client added' do
    returned = questionnaire([question('Q1')])
    sent = questionnaire([question('Q1'), question('Q2')])

    expect(summarize(returned, sent)).to eq([[:question_added, 'Q2', '']])
  end

  it 'reports a question whose required flag was turned off' do
    returned = questionnaire([question('Q1', required: true)])
    sent = questionnaire([question('Q1', required: false)])

    findings = described_class.new(returned, sent).findings

    expect(summarize(returned, sent)).to eq([[:question_altered, 'Q1', '']])
    expect(findings.first.message).to include('differs from the question the payer returned (required)')
  end

  it 'reports a condition the client attached to turn a question off' do
    returned = questionnaire([question('Q0'), question('Q1', required: true)])
    sent = questionnaire([
                           question('Q0'),
                           question('Q1', required: true,
                                          enableWhen: [
                                            FHIR::Questionnaire::Item::EnableWhen.new(question: 'Q0', operator: '=',
                                                                                      answerString: 'never')
                                          ])
                         ])

    findings = described_class.new(returned, sent).findings

    expect(summarize(returned, sent)).to eq([[:question_altered, 'Q1', '']])
    expect(findings.first.message).to include('enableWhen')
  end

  it 'reports a changed question type' do
    returned = questionnaire([question('Q1', type: 'string')])
    sent = questionnaire([question('Q1', type: 'display')])

    expect(summarize(returned, sent)).to eq([[:question_altered, 'Q1', '']])
  end

  it 'compares nested questions where they sit' do
    returned = questionnaire([question('G', type: 'group', item: [question('Q1', required: true)])])
    sent = questionnaire([question('G', type: 'group', item: [])])

    expect(summarize(returned, sent)).to eq([[:question_removed, 'Q1', 'G']])
  end

  it 'reports a branch that went missing whole at its top' do
    returned = questionnaire([question('G', type: 'group',
                                            item: [question('Q1', required: true), question('Q2')])])
    sent = questionnaire([])

    expect(summarize(returned, sent)).to eq([[:question_removed, 'G', '']])
  end

  it 'reports a branch that was added whole at its top' do
    returned = questionnaire([])
    sent = questionnaire([question('G', type: 'group', item: [question('Q1')])])

    expect(summarize(returned, sent)).to eq([[:question_added, 'G', '']])
  end

  it 'does not confuse questions that repeat a link id at one level' do
    returned = questionnaire([question('Q1'), question('Q1', required: true)])
    sent = questionnaire([question('Q1')])

    expect(summarize(returned, sent)).to eq([[:question_removed, 'Q1[2]', '']])
  end

  it 'ignores parts of a question that do not decide whether it needs an answer' do
    returned = questionnaire([question('Q1', text: 'Original wording')])
    sent = questionnaire([question('Q1', text: 'Reworded by the client')])

    expect(described_class.new(returned, sent).findings).to be_empty
  end
end
