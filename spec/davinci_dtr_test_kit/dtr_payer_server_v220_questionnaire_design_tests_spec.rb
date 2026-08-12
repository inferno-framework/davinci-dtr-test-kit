# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design_tests'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireRelevanceLogicTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:test_run) { repo_create(:test_run, test_session:, runnable: described_class.reference_hash) }
  let(:result) { repo_create(:result, test_session:, test_run:, runnable: described_class.reference_hash) }
  let(:questionnaire_url) { "/custom/#{suite_id}/Questionnaire/$questionnaire-package" }
  let(:enable_when_expression_url) do
    DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireDesignValidation::ENABLE_WHEN_EXPRESSION_URL
  end
  let(:initial_expression_url) do
    'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'
  end

  def questionnaire_item(link_id: 'item-1', extensions: [], enable_when: [], items: [])
    FHIR::Questionnaire::Item.new(
      linkId: link_id,
      type: 'string',
      extension: extensions,
      enableWhen: enable_when,
      item: items
    )
  end

  def questionnaire(items: [], extensions: [])
    FHIR::Questionnaire.new(status: 'draft', item: items, extension: extensions)
  end

  def expression_extension(url, language: 'text/cql')
    FHIR::Extension.new(
      url:,
      valueExpression: FHIR::Expression.new(language:, expression: 'ExampleExpression')
    )
  end

  def questionnaire_package_response(*questionnaires)
    bundle = FHIR::Bundle.new(
      type: 'collection',
      entry: questionnaires.map { |resource| FHIR::Bundle::Entry.new(resource:) }
    )
    FHIR::Parameters.new(
      parameter: [FHIR::Parameters::Parameter.new(name: 'packagebundle', resource: bundle)]
    ).to_json
  end

  def next_question_response(questionnaire)
    FHIR::QuestionnaireResponse.new(status: 'in-progress', contained: [questionnaire]).to_json
  end

  def store_response(response_body, tags: [DaVinciDTRTestKit::QUESTIONNAIRE_TAG])
    repo_create(
      :request,
      direction: 'outgoing',
      url: questionnaire_url,
      test_session_id: test_session.id,
      result:,
      request_body: '{}',
      response_body:,
      tags:,
      status: 200
    )
  end

  describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireRelevanceLogicTest do # spec-17
    it 'skips when no Questionnaire resources were returned' do
      expect(run(described_class).result).to eq('skip')
    end

    it 'passes when a nested item includes enableWhen' do
      enable_when = FHIR::Questionnaire::Item::EnableWhen.new(
        question: 'prior-item', operator: '=', answerBoolean: true
      )
      nested_item = questionnaire_item(enable_when: [enable_when])
      parent_item = questionnaire_item(link_id: 'parent', items: [nested_item])
      store_response(questionnaire_package_response(questionnaire(items: [parent_item])))

      expect(run(described_class).result).to eq('pass')
    end

    it 'loads and passes Questionnaires returned by $next-question' do
      item = questionnaire_item(extensions: [expression_extension(enable_when_expression_url)])
      store_response(
        next_question_response(questionnaire(items: [item])),
        tags: [DaVinciDTRTestKit::NEXT_TAG]
      )

      expect(run(described_class).result).to eq('pass')
    end

    it 'passes when at least one returned Questionnaire includes relevance logic' do
      enable_when = FHIR::Questionnaire::Item::EnableWhen.new(
        question: 'prior-item', operator: '=', answerBoolean: true
      )
      questionnaire_with_logic = questionnaire(
        items: [questionnaire_item(enable_when: [enable_when])]
      )
      questionnaire_without_logic = questionnaire(items: [questionnaire_item])
      store_response(questionnaire_package_response(questionnaire_without_logic))
      store_response(next_question_response(questionnaire_with_logic), tags: [DaVinciDTRTestKit::NEXT_TAG])

      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when none of the Questionnaires include relevance logic' do
      store_response(questionnaire_package_response(questionnaire(items: [questionnaire_item])))

      test_result = run(described_class)
      expect(test_result.result).to eq('fail')
      expect(test_result.result_message).to include('enableWhen')
    end
  end

  describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireExpressionLanguageTest do # spec-18
    it 'passes when flow expressions use CQL' do
      item = questionnaire_item(extensions: [expression_extension(enable_when_expression_url)])
      store_response(questionnaire_package_response(questionnaire(items: [item])))

      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when an expression uses a language other than the text/cql used by the previous test' do
      extension = expression_extension(enable_when_expression_url, language: 'text/cql-identifier')
      item = questionnaire_item(extensions: [extension])
      store_response(questionnaire_package_response(questionnaire(items: [item])))

      expect(run(described_class).result).to eq('fail')
    end

    it 'fails when a flow expression does not use CQL' do
      extension = expression_extension(enable_when_expression_url, language: 'text/fhirpath')
      item = questionnaire_item(link_id: 'conditional-item', extensions: [extension])
      store_response(questionnaire_package_response(questionnaire(items: [item])))

      test_result = run(described_class)
      expect(test_result.result).to eq('fail')
      expect(test_result.result_message).to include('conditional-item', 'text/fhirpath')
    end

    it 'checks Expression-valued item extensions as the previous test did' do
      initial_expression = expression_extension(initial_expression_url, language: 'text/fhirpath')
      item = questionnaire_item(link_id: 'prepopulated-item', extensions: [initial_expression])
      store_response(questionnaire_package_response(questionnaire(items: [item])))

      test_result = run(described_class)
      expect(test_result.result).to eq('fail')
      expect(test_result.result_message).to include('prepopulated-item', 'text/fhirpath')
    end

    it 'omits when no Expression-valued item extensions are present' do
      store_response(questionnaire_package_response(questionnaire(items: [questionnaire_item])))

      expect(run(described_class).result).to eq('omit')
    end
  end

  describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnairePrepopulationTest do # spec-54
    it 'passes when at least one of several Questionnaires includes prepopulation logic' do
      bare_questionnaire = questionnaire(items: [questionnaire_item])
      variable_url = 'http://hl7.org/fhir/StructureDefinition/variable'
      populated_questionnaire = questionnaire(extensions: [expression_extension(variable_url)])
      store_response(questionnaire_package_response(bare_questionnaire, populated_questionnaire))

      expect(run(described_class).result).to eq('pass')
    end

    it 'fails when no Questionnaire includes prepopulation logic' do
      store_response(questionnaire_package_response(questionnaire(items: [questionnaire_item])))

      test_result = run(described_class)
      expect(test_result.result).to eq('fail')
      expect(test_result.result_message).to include('population from the EHR')
    end
  end
end