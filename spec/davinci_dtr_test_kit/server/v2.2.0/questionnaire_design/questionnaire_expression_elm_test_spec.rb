# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/questionnaire_expression_elm_test'
require_relative 'questionnaire_design_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireExpressionElmTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  include QuestionnaireDesignSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:test_run) { repo_create(:test_run, test_session:, runnable: described_class.reference_hash) }
  let(:result) { repo_create(:result, test_session:, test_run:, runnable: described_class.reference_hash) }
  let(:questionnaire_url) { "/custom/#{suite_id}/Questionnaire/$questionnaire-package" }
  let(:initial_expression_url) do
    'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'
  end

  def result_messages
    results_repo
      .current_results_for_test_session_and_runnables(test_session.id, [described_class])
      .first&.messages || []
  end

  it 'passes when every expression includes an Alternative Expression extension' do
    item = questionnaire_item(extensions: [expression_extension(initial_expression_url)])
    store_response(questionnaire_package_response(questionnaire(items: [item])))

    expect(run(described_class).result).to eq('pass')
  end

  it 'fails when an expression does not include an Alternative Expression extension' do
    extension = expression_extension(initial_expression_url)
    extension.valueExpression.extension.clear
    item = questionnaire_item(
      link_id: 'prepopulated-item',
      extensions: [extension]
    )
    store_response(questionnaire_package_response(questionnaire(items: [item])))

    test_result = run(described_class)
    expect(test_result.result).to eq('fail')
    expect(result_messages.first.message).to include('$questionnaire-package request 1', 'prepopulated-item')
  end

  it 'omits when no CQL expressions are present' do
    item = questionnaire_item(
      extensions: [expression_extension(initial_expression_url, language: 'text/fhirpath')]
    )
    store_response(questionnaire_package_response(questionnaire(items: [item])))

    expect(run(described_class).result).to eq('omit')
  end
end
