require 'davinci_dtr_test_kit/cross_suite/v2.2.0/questionnaire_response_checker'

RSpec.describe DaVinciDTRTestKit::QuestionnaireResponseChecker do
  def fixture(name)
    FHIR.from_contents(File.read(File.join(__dir__, '..', 'fixtures', name)))
  end

  def findings_for(questionnaire, questionnaire_response)
    described_class.new(questionnaire, questionnaire_response).findings
  end

  def summarize(findings)
    findings.map { |finding| [finding.type, finding.link_id, finding.path] }
  end

  def questionnaire_with_items(items)
    FHIR::Questionnaire.new(status: 'draft', item: items)
  end

  def question(link_id, attributes = {})
    FHIR::Questionnaire::Item.new({ linkId: link_id, type: 'string' }.merge(attributes))
  end

  def enable_when(question_link_id, operator, answer_attributes)
    FHIR::Questionnaire::Item::EnableWhen.new(
      { question: question_link_id, operator: }.merge(answer_attributes)
    )
  end

  def response_with_items(items)
    FHIR::QuestionnaireResponse.new(status: 'in-progress', item: items)
  end

  def answered_item(link_id, *values, nested_items: [])
    FHIR::QuestionnaireResponse::Item.new(
      linkId: link_id,
      answer: values.map do |value|
        FHIR::QuestionnaireResponse::Item::Answer.new(valueString: value, item: nested_items)
      end
    )
  end

  describe 'required questions' do
    it 'returns no findings when a required question is answered' do
      questionnaire = questionnaire_with_items([question('Q1', required: true)])
      response = response_with_items([answered_item('Q1', 'an answer')])

      expect(findings_for(questionnaire, response)).to be_empty
    end

    it 'reports a required question that has no matching response item' do
      questionnaire = questionnaire_with_items([question('Q1', required: true)])

      findings = findings_for(questionnaire, response_with_items([]))

      expect(summarize(findings)).to eq([[:required_unanswered, 'Q1', '']])
      expect(findings.first.message).to eq('Item `Q1` is required and enabled, but has no answer.')
    end

    it 'reports a required question whose response item has no answer' do
      questionnaire = questionnaire_with_items([question('Q1', required: true)])
      response = response_with_items([FHIR::QuestionnaireResponse::Item.new(linkId: 'Q1')])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:required_unanswered, 'Q1', '']])
    end

    it 'returns no findings for an unanswered optional question' do
      questionnaire = questionnaire_with_items([question('Q1', required: false)])

      expect(findings_for(questionnaire, response_with_items([]))).to be_empty
    end

    it 'treats a boolean false answer as an answer' do
      questionnaire = questionnaire_with_items([question('Q1', type: 'boolean', required: true)])
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Q1',
                                         answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueBoolean: false)]
                                       )
                                     ])

      expect(findings_for(questionnaire, response)).to be_empty
    end
  end

  describe 'groups' do
    let(:questionnaire) do
      questionnaire_with_items([
                                 question('Group1', type: 'group', item: [question('Q1', required: true)])
                               ])
    end

    it 'reports a required question nested within a group that is present' do
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Group1', item: [answered_item('Q2', 'unrelated')]
                                       )
                                     ])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:required_unanswered, 'Q1', 'Group1']])
    end

    # `required` only applies once the parent is present, so an optional group that holds required
    # questions needs no answers at all until the group itself is answered.
    it 'does not report the questions within an optional group that is absent from the response' do
      expect(findings_for(questionnaire, response_with_items([]))).to be_empty
    end

    it 'does not report the questions within an optional group that holds no answers' do
      response = response_with_items([FHIR::QuestionnaireResponse::Item.new(linkId: 'Group1')])

      expect(findings_for(questionnaire, response)).to be_empty
    end

    # A required group that is missing is reported as missing itself, and its descendants are left
    # alone: reporting the group is enough to say the whole branch is unanswered.
    it 'reports a required group that is absent from the response, and nothing within it' do
      required_group = questionnaire_with_items([
                                                  question('Group1', type: 'group', required: true,
                                                                     item: [question('Q1', required: true)])
                                                ])

      expect(summarize(findings_for(required_group, response_with_items([]))))
        .to eq([[:required_unanswered, 'Group1', '']])
    end

    it 'reports a required group that holds no answers, and nothing within it' do
      required_group = questionnaire_with_items([
                                                  question('Group1', type: 'group', required: true,
                                                                     item: [question('Q1', required: true)])
                                                ])
      response = response_with_items([FHIR::QuestionnaireResponse::Item.new(linkId: 'Group1')])

      expect(summarize(findings_for(required_group, response)))
        .to eq([[:required_unanswered, 'Group1', '']])
    end

    it 'does not report questions within a group that is not enabled' do
      gated = questionnaire_with_items([
                                         question('Q0'),
                                         question('Group1', type: 'group',
                                                            enableWhen: [enable_when('Q0', '=',
                                                                                     { answerString: 'no' })],
                                                            item: [question('Q1', required: true)])
                                       ])
      response = response_with_items([answered_item('Q0', 'yes')])

      expect(findings_for(gated, response)).to be_empty
    end

    it 'reports a group that has answers of its own' do
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Group1',
                                         answer: [FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'nope')],
                                         item: [answered_item('Q1', 'an answer')]
                                       )
                                     ])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:group_with_answers, 'Group1', '']])
    end

    it 'evaluates each repetition of a repeating group separately' do
      repeating = questionnaire_with_items([
                                             question('Group1', type: 'group', repeats: true,
                                                                item: [question('Q1', required: true)])
                                           ])
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Group1', item: [answered_item('Q1', 'an answer')]
                                       ),
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Group1', item: [answered_item('Q2', 'unrelated')]
                                       )
                                     ])

      expect(summarize(findings_for(repeating, response))).to eq([[:required_unanswered, 'Q1', 'Group1[2]']])
    end
  end

  describe 'nested items under a question' do
    let(:questionnaire) do
      questionnaire_with_items([question('Q1', required: true, item: [question('Q1.1', required: true)])])
    end

    it 'evaluates nested questions within each answer' do
      response = response_with_items([answered_item('Q1', 'an answer')])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:required_unanswered, 'Q1.1', 'Q1']])
    end

    it 'reports nested items that are not within an answer' do
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Q1',
                                         answer: [
                                           FHIR::QuestionnaireResponse::Item::Answer.new(
                                             valueString: 'an answer',
                                             item: [answered_item('Q1.1', 'nested answer')]
                                           )
                                         ],
                                         item: [answered_item('Q1.1', 'misplaced answer')]
                                       )
                                     ])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:items_outside_answer, 'Q1', '']])
    end

    it 'labels the answer each finding belongs to when a question has several answers' do
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'Q1',
                                         answer: [
                                           FHIR::QuestionnaireResponse::Item::Answer.new(
                                             valueString: 'first',
                                             item: [answered_item('Q1.1', 'nested answer')]
                                           ),
                                           FHIR::QuestionnaireResponse::Item::Answer.new(valueString: 'second')
                                         ]
                                       )
                                     ])

      expect(summarize(findings_for(questionnaire, response))).to eq(
        [[:required_unanswered, 'Q1.1', 'Q1[answer 2]']]
      )
    end
  end

  describe 'enableWhen conditions' do
    let(:questionnaire) do
      questionnaire_with_items([
                                 question('Q1'),
                                 question('Q2', required: true,
                                                enableWhen: [enable_when('Q1', '=', { answerString: 'no' })])
                               ])
    end

    it 'does not require a question whose condition is not met' do
      response = response_with_items([answered_item('Q1', 'yes')])

      expect(findings_for(questionnaire, response)).to be_empty
    end

    it 'requires a question whose condition is met' do
      response = response_with_items([answered_item('Q1', 'no')])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:required_unanswered, 'Q2', '']])
    end

    it 'reports a question that is answered even though its condition is not met' do
      response = response_with_items([answered_item('Q1', 'yes'), answered_item('Q2', 'an answer')])

      findings = findings_for(questionnaire, response)

      expect(summarize(findings)).to eq([[:answered_while_disabled, 'Q2', '']])
      expect(findings.first.message).to eq(
        'Item `Q2` has an answer, but is not enabled based on its `enableWhen` condition(s).'
      )
    end

    it 'treats the condition as met when any answer to the referenced question satisfies it' do
      response = response_with_items([answered_item('Q1', 'maybe', 'no')])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:required_unanswered, 'Q2', '']])
    end

    it 'does not evaluate questions nested within a question that is not enabled' do
      nested = questionnaire_with_items([
                                          question('Q1'),
                                          question('Q2', enableWhen: [enable_when('Q1', '=', { answerString: 'no' })],
                                                         item: [question('Q2.1', required: true)])
                                        ])
      response = response_with_items([answered_item('Q1', 'yes')])

      expect(findings_for(nested, response)).to be_empty
    end

    describe 'enableBehavior' do
      let(:conditions) do
        [enable_when('Q1', '=', { answerString: 'no' }), enable_when('Q1b', '=', { answerString: 'yes' })]
      end
      let(:response) { response_with_items([answered_item('Q1', 'no'), answered_item('Q1b', 'other')]) }

      it 'requires only one condition to be met when enableBehavior is absent' do
        questionnaire = questionnaire_with_items([question('Q1'), question('Q1b'),
                                                  question('Q2', required: true, enableWhen: conditions)])

        expect(summarize(findings_for(questionnaire, response))).to eq([[:required_unanswered, 'Q2', '']])
      end

      it 'requires every condition to be met when enableBehavior is all' do
        questionnaire = questionnaire_with_items([question('Q1'), question('Q1b'),
                                                  question('Q2', required: true, enableWhen: conditions,
                                                                 enableBehavior: 'all')])

        expect(findings_for(questionnaire, response)).to be_empty
      end
    end

    describe 'operators' do
      def findings_with_condition(operator, answer_attributes, response_item)
        questionnaire = questionnaire_with_items([
                                                   question('Q1'),
                                                   question('Q2', required: true,
                                                                  enableWhen: [enable_when('Q1', operator,
                                                                                           answer_attributes)])
                                                 ])
        findings_for(questionnaire, response_with_items([response_item]))
      end

      def item_with_answer(link_id, answer_attributes)
        FHIR::QuestionnaireResponse::Item.new(
          linkId: link_id,
          answer: [FHIR::QuestionnaireResponse::Item::Answer.new(answer_attributes)]
        )
      end

      it 'treats exists as met when the referenced question has an answer' do
        expect(findings_with_condition('exists', { answerBoolean: true }, answered_item('Q1', 'anything')))
          .to_not be_empty
      end

      it 'treats exists with a false answer as met when the referenced question has no answer' do
        expect(findings_with_condition('exists', { answerBoolean: false },
                                       FHIR::QuestionnaireResponse::Item.new(linkId: 'Q1'))).to_not be_empty
      end

      it 'evaluates not equal conditions' do
        expect(findings_with_condition('!=', { answerString: 'no' }, answered_item('Q1', 'yes'))).to_not be_empty
      end

      it 'evaluates ordering conditions on numbers' do
        expect(findings_with_condition('>', { answerInteger: 3 }, item_with_answer('Q1', valueInteger: 5)))
          .to_not be_empty
        expect(findings_with_condition('>', { answerInteger: 3 }, item_with_answer('Q1', valueInteger: 2))).to be_empty
      end

      it 'compares Coding answers by system and code' do
        coding = FHIR::Coding.new(system: 'http://example.com/cs', code: 'burger')
        answer = item_with_answer('Q1', valueCoding: FHIR::Coding.new(system: 'http://example.com/cs',
                                                                      code: 'burger', display: 'Hamburger'))

        expect(findings_with_condition('=', { answerCoding: coding }, answer)).to_not be_empty
      end

      it 'does not compare quantities with different units' do
        expected = FHIR::Quantity.new(value: 2, system: 'http://unitsofmeasure.org', code: 'kg')
        answer = item_with_answer('Q1', valueQuantity: FHIR::Quantity.new(value: 5,
                                                                          system: 'http://unitsofmeasure.org',
                                                                          code: 'g'))

        expect(findings_with_condition('>', { answerQuantity: expected }, answer)).to be_empty
      end
    end
  end

  describe 'what counts as a duplicate finding' do
    let(:gate) { [enable_when('GATE', '=', { answerString: 'no' })] }

    it 'reports a disabled question once however many answers it has' do
      questionnaire = questionnaire_with_items([question('GATE'), question('Q1', enableWhen: gate)])
      response = response_with_items([answered_item('GATE', 'yes'), answered_item('Q1', 'a', 'b', 'c')])

      expect(summarize(findings_for(questionnaire, response))).to eq([[:answered_while_disabled, 'Q1', '']])
    end

    it 'names the repetition so two occurrences of one question are reported separately' do
      questionnaire = questionnaire_with_items([question('GATE'),
                                                question('Q1', repeats: true, enableWhen: gate)])
      response = response_with_items([answered_item('GATE', 'yes'), answered_item('Q1', 'a'),
                                      answered_item('Q1', 'b')])

      expect(summarize(findings_for(questionnaire, response))).to eq(
        [
          [:answered_while_disabled, 'Q1[1]', ''],
          [:answered_while_disabled, 'Q1[2]', '']
        ]
      )
    end

    it 'reports the same question at different paths separately' do
      questionnaire = questionnaire_with_items([
                                                 question('GRP', type: 'group', repeats: true,
                                                                 item: [question('Q1', required: true)])
                                               ])
      response = response_with_items([
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'GRP', item: [answered_item('X', 'a')]
                                       ),
                                       FHIR::QuestionnaireResponse::Item.new(
                                         linkId: 'GRP', item: [answered_item('Y', 'b')]
                                       )
                                     ])

      expect(summarize(findings_for(questionnaire, response))).to eq(
        [
          [:required_unanswered, 'Q1', 'GRP[1]'],
          [:required_unanswered, 'Q1', 'GRP[2]']
        ]
      )
    end
  end

  # Inferno has no way to evaluate these expressions, so an item that carries one is presumed to have
  # been handled correctly and the enablement rules never report it.
  describe 'enableWhenExpression extension' do
    def expression_extension
      FHIR::Extension.new(
        url: 'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression',
        valueExpression: FHIR::Expression.new(language: 'text/fhirpath',
                                              expression: '%resource.item.count() > 0')
      )
    end

    let(:questionnaire) do
      questionnaire_with_items([question('Q1', extension: [expression_extension], required: true)])
    end

    it 'reports an informational finding rather than an error when the item is unanswered' do
      findings = findings_for(questionnaire, response_with_items([]))

      expect(summarize(findings)).to eq([[:enable_when_expression_not_evaluated, 'Q1', '']])
      expect(findings.first.severity).to eq(:info)
      expect(findings.first.message).to eq(
        'Item `Q1` has an `enableWhenExpression` extension, which Inferno does not evaluate, ' \
        'so whether it is enabled was presumed from whether it has an answer.'
      )
    end

    it 'presumes an answered item was enabled' do
      response = response_with_items([answered_item('Q1', 'an answer')])

      expect(summarize(findings_for(questionnaire, response)))
        .to eq([[:enable_when_expression_not_evaluated, 'Q1', '']])
    end

    it 'presumes the item was handled correctly even when its enableWhen conditions say otherwise' do
      both = questionnaire_with_items([
                                        question('Q0'),
                                        question('Q1', required: true, extension: [expression_extension],
                                                       enableWhen: [enable_when('Q0', '=', { answerString: 'no' })])
                                      ])
      response = response_with_items([answered_item('Q0', 'yes'), answered_item('Q1', 'an answer')])

      expect(summarize(findings_for(both, response)))
        .to eq([[:enable_when_expression_not_evaluated, 'Q1', '']])
    end

    it 'still checks the questions within an item that was answered' do
      nested = questionnaire_with_items([
                                          question('Q1', extension: [expression_extension],
                                                         item: [question('Q1.1', required: true)])
                                        ])
      response = response_with_items([answered_item('Q1', 'an answer')])

      expect(summarize(findings_for(nested, response))).to eq(
        [
          [:enable_when_expression_not_evaluated, 'Q1', ''],
          [:required_unanswered, 'Q1.1', 'Q1']
        ]
      )
    end

    it 'notes the expression once for an item that repeats' do
      repeating = questionnaire_with_items([question('Q1', repeats: true, extension: [expression_extension])])
      response = response_with_items([answered_item('Q1', 'first'), answered_item('Q1', 'second')])

      expect(summarize(findings_for(repeating, response)))
        .to eq([[:enable_when_expression_not_evaluated, 'Q1', '']])
    end
  end

  describe "Karl's multiple parent example" do
    let(:questionnaire) { fixture('enable_when_multiple_parent_questionnaire.json') }

    it 'returns no findings for the response that answers each concern correctly' do
      response = fixture('enable_when_multiple_parent_valid_response.json')

      expect(findings_for(questionnaire, response)).to be_empty
    end

    # The expected errors are recorded in `urn:inferno:comment` extensions within the fixture.
    it 'reports the four expected errors for the response with misplaced and missing answers' do
      response = fixture('enable_when_multiple_parent_invalid_response.json')

      expect(summarize(findings_for(questionnaire, response))).to eq(
        [
          [:answered_while_disabled, 'concern.other', 'concern[answer 1]'],
          [:answered_while_disabled, 'concern.contact', 'concern[answer 1]'],
          [:required_unanswered, 'concern.other', 'concern[answer 2]'],
          [:required_unanswered, 'concern.contact', 'concern[answer 2]']
        ]
      )
    end
  end

  describe "Karl's search example" do
    let(:questionnaire) { fixture('enable_when_search_questionnaire.json') }

    it 'enables questions whose conditions are met by preceding and following answers' do
      response = fixture('enable_when_search_valid_response.json')

      expect(findings_for(questionnaire, response)).to be_empty
    end

    # `backward-search` looks backwards for `concern.other` and reaches the second concern's answer
    # first, which does not match, so it should not have been answered.
    it 'reports the question enabled by the wrong occurrence of a repeated answer' do
      response = fixture('enable_when_search_invalid_response.json')

      expect(summarize(findings_for(questionnaire, response))).to eq(
        [[:answered_while_disabled, 'backward-search', '']]
      )
    end
  end
end
