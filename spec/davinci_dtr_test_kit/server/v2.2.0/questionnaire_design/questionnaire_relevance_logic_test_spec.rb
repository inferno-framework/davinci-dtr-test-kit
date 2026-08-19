# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/questionnaire_relevance_logic_test'
require_relative 'questionnaire_design_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireRelevanceLogicTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  include QuestionnaireDesignSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:test_run) { repo_create(:test_run, test_session:, runnable: described_class.reference_hash) }
  let(:result) { repo_create(:result, test_session:, test_run:, runnable: described_class.reference_hash) }
  let(:questionnaire_url) { "/custom/#{suite_id}/Questionnaire/$questionnaire-package" }
  let(:enable_when_expression_url) do
    described_class::ENABLE_WHEN_EXPRESSION_URL
  end

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

  it 'passes when a Questionnaire returned by $next-question includes enableWhenExpression' do
    questionnaire_without_logic = questionnaire(items: [questionnaire_item])
    store_response(questionnaire_package_response(questionnaire_without_logic))

    item = questionnaire_item(extensions: [expression_extension(enable_when_expression_url)])
    store_response(
      next_question_response(questionnaire(items: [item])),
      tags: [DaVinciDTRTestKit::NEXT_TAG]
    )

    expect(run(described_class).result).to eq('pass')
  end

  it 'fails when none of the Questionnaires include relevance logic' do
    store_response(questionnaire_package_response(questionnaire(items: [questionnaire_item])))

    test_result = run(described_class)
    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include('enableWhen')
  end
end
