# frozen_string_literal: true

require 'davinci_dtr_test_kit/server/v2.2.0/questionnaire_design/questionnaire_expression_language_test'
require_relative 'questionnaire_design_spec_helpers'

RSpec.describe DaVinciDTRTestKit::DTRPayerServerV220::QuestionnaireExpressionLanguageTest, :runnable do # rubocop:disable RSpec/SpecFilePathFormat
  include QuestionnaireDesignSpecHelpers

  let(:suite_id) { 'dtr_payer_server_v220' }
  let(:test_run) { repo_create(:test_run, test_session:, runnable: described_class.reference_hash) }
  let(:result) { repo_create(:result, test_session:, test_run:, runnable: described_class.reference_hash) }
  let(:questionnaire_url) { "/custom/#{suite_id}/Questionnaire/$questionnaire-package" }
  let(:enable_when_expression_url) do
    'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-enableWhenExpression'
  end
  let(:initial_expression_url) do
    'http://hl7.org/fhir/uv/sdc/StructureDefinition/sdc-questionnaire-initialExpression'
  end

  it 'passes when flow expressions use CQL' do
    item = questionnaire_item(extensions: [expression_extension(enable_when_expression_url)])
    store_response(questionnaire_package_response(questionnaire(items: [item])))

    expect(run(described_class).result).to eq('pass')
  end

  it 'fails when a flow expression does not use CQL' do
    extension = expression_extension(enable_when_expression_url, language: 'text/fhirpath')
    item = questionnaire_item(link_id: 'conditional-item', extensions: [extension])
    store_response(questionnaire_package_response(questionnaire(items: [item])))

    test_result = run(described_class)
    expect(test_result.result).to eq('fail')
    expect(test_result.result_message).to include('conditional-item', 'text/fhirpath')
  end

  it 'fails when an item expression does not use CQL' do
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
